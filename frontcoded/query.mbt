///|
/// Number of distinct terms.
pub fn Dictionary::length(self : Dictionary) -> Int {
  self.terms
}

///|
/// Configured number of terms per restart block.
pub fn Dictionary::block_size(self : Dictionary) -> Int {
  self.block_size
}

///|
/// Number of restart blocks.
pub fn Dictionary::block_count(self : Dictionary) -> Int {
  self.block_offsets.length()
}

///|
/// Encoded record bytes excluding an outer file-format envelope.
pub fn Dictionary::encoded_bytes(self : Dictionary) -> Int {
  self.encoded.length()
}

///|
fn Dictionary::decode_in_block(
  self : Dictionary,
  block : Int,
  target : Int,
) -> Bytes raise @support.SuccinctError {
  let reader = @binary.Reader::new(self.encoded)
  reader.skip(self.block_offsets[block], context="front-coded block offset")
  let mut term = reader.read_term("front-coded restart term")
  let block_start = block * self.block_size
  for index = block_start + 1; index <= target; index = index + 1 {
    let prefix64 = reader.read_varint(context="front-coded prefix length")
    if prefix64 > term.length().to_uint64() {
      raise @support.SuccinctError::InvalidEncoding(
        offset=reader.position(),
        context="front-coded term",
        detail="prefix exceeds previous term",
      )
    }
    let suffix = reader.read_term("front-coded suffix")
    term = @support.join_prefix_suffix(term, prefix64.to_int(), suffix)
  }
  term
}

///|
/// Optional random access by lexicographic term number.
pub fn Dictionary::get(
  self : Dictionary,
  index : Int,
) -> Bytes? raise @support.SuccinctError {
  if index < 0 || index >= self.terms {
    None
  } else {
    Some(self.decode_in_block(index / self.block_size, index))
  }
}

///|
/// Checked random access by lexicographic term number.
pub fn Dictionary::at(
  self : Dictionary,
  index : Int,
) -> Bytes raise @support.SuccinctError {
  match self.get(index) {
    Some(term) => term
    None =>
      raise @support.SuccinctError::OutOfRange(
        context="front-coded term",
        index~,
        length=self.terms,
      )
  }
}

///|
/// First term number whose term is greater than or equal to target.
pub fn Dictionary::lower_bound(
  self : Dictionary,
  target : Bytes,
) -> Int raise @support.SuccinctError {
  let mut low = 0
  let mut high = self.terms
  while low < high {
    let middle = low + (high - low) / 2
    if @support.compare_bytes(self.at(middle), target) < 0 {
      low = middle + 1
    } else {
      high = middle
    }
  }
  low
}

///|
/// Exact lexicographic term number.
pub fn Dictionary::term_number(
  self : Dictionary,
  target : Bytes,
) -> Int? raise @support.SuccinctError {
  let index = self.lower_bound(target)
  if index < self.terms && @support.compare_bytes(self.at(index), target) == 0 {
    Some(index)
  } else {
    None
  }
}

///|
/// Exact membership.
pub fn Dictionary::contains(
  self : Dictionary,
  target : Bytes,
) -> Bool raise @support.SuccinctError {
  self.term_number(target) is Some(_)
}

///|
/// Half-open range of terms beginning with prefix.
pub fn Dictionary::prefix_range(
  self : Dictionary,
  prefix : Bytes,
) -> TermRange raise @support.SuccinctError {
  let start = self.lower_bound(prefix)
  let mut end = start
  while end < self.terms && @support.starts_with_bytes(self.at(end), prefix) {
    end += 1
  }
  { start, end, }
}

///|
/// Enumerate up to limit matching terms.
pub fn Dictionary::terms_with_prefix(
  self : Dictionary,
  prefix : Bytes,
  limit : Int,
) -> Array[Bytes] raise @support.SuccinctError {
  if limit < 0 {
    raise @support.SuccinctError::InvalidArgument(
      context="dictionary enumeration limit",
      detail="must be non-negative",
    )
  }
  let range = self.prefix_range(prefix)
  let output : Array[Bytes] = []
  let mut index = range.start
  while index < range.end && output.length() < limit {
    output.push(self.at(index))
    index += 1
  }
  output
}

///|
/// Materialize all terms in lexicographic order.
pub fn Dictionary::to_terms(
  self : Dictionary,
) -> Array[Bytes] raise @support.SuccinctError {
  let output : Array[Bytes] = []
  for index = 0; index < self.terms; index = index + 1 {
    output.push(self.at(index))
  }
  output
}
