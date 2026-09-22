///|
/// Build a dictionary after sorting and deduplicating arbitrary byte terms.
pub fn from_terms(
  input : Array[Bytes],
  block_size? : Int = 8,
) -> Dictionary raise @support.SuccinctError {
  if block_size <= 0 {
    raise @support.SuccinctError::InvalidArgument(
      context="front-coded block size",
      detail="must be positive",
    )
  }
  let terms = copy_terms(input)
  sort_terms(terms)
  let distinct = deduplicate_sorted(terms)
  let writer = @binary.Writer::new()
  let block_offsets : Array[Int] = []
  let mut previous = b""
  for index = 0; index < distinct.length(); index = index + 1 {
    let term = distinct[index]
    if index % block_size == 0 {
      block_offsets.push(writer.length())
      writer.write_length_prefixed(term)
    } else {
      let shared = @support.common_prefix_length(previous, term)
      writer.write_varint(shared.to_uint64())
      let suffix : Array[Byte] = []
      for offset = shared; offset < term.length(); offset = offset + 1 {
        suffix.push(term[offset])
      }
      writer.write_length_prefixed(Bytes::from_array(suffix))
    }
    previous = term
  }
  {
    terms: distinct.length(),
    block_size,
    encoded: writer.finish(),
    block_offsets,
  }
}

///|
/// Reconstruct parts while validating every record and sorted invariant.
fn from_parts(
  terms : Int,
  block_size : Int,
  encoded : Bytes,
  block_offsets : Array[Int],
  limits? : @support.DecodeLimits = @support.DecodeLimits::sensible(),
) -> Dictionary raise @support.SuccinctError {
  if terms < 0 || block_size <= 0 {
    raise @support.SuccinctError::InvalidArgument(
      context="front-coded metadata",
      detail="invalid term count or block size",
    )
  }
  let expected_blocks = if terms == 0 {
    0
  } else {
    (terms - 1) / block_size + 1
  }
  if block_offsets.length() != expected_blocks {
    raise @support.SuccinctError::InvalidArgument(
      context="front-coded block offsets",
      detail="block count does not match term count",
    )
  }
  if expected_blocks == 0 && encoded.length() != 0 {
    raise @support.SuccinctError::InvalidEncoding(
      offset=0,
      context="front-coded dictionary",
      detail="empty dictionary must not contain record bytes",
    )
  }
  let copied_offsets : Array[Int] = []
  for index = 0; index < block_offsets.length(); index = index + 1 {
    let offset = block_offsets[index]
    if offset < 0 ||
      offset >= encoded.length() ||
      (index > 0 && offset <= block_offsets[index - 1]) {
      raise @support.SuccinctError::InvalidSequence(
        index~,
        detail="block offsets must be increasing encoded positions",
      )
    }
    copied_offsets.push(offset)
  }
  let candidate = {
    terms,
    block_size,
    encoded: @support.copy_bytes(encoded),
    block_offsets: copied_offsets,
  }
  let mut previous : Bytes? = None
  let mut decoded_term_bytes = 0
  for block = 0; block < expected_blocks; block = block + 1 {
    let reader = @binary.Reader::new(candidate.encoded, limits~)
    reader.skip(
      candidate.block_offsets[block],
      context="front-coded block offset",
    )
    let block_start = block * block_size
    let remaining = terms - block_start
    let block_end = if block_size < remaining {
      block_start + block_size
    } else {
      terms
    }
    let mut term = reader.read_term("front-coded restart term")
    for index = block_start; index < block_end; index = index + 1 {
      if index > block_start {
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
      limits.check_term(term.length())
      if term.length() > 2147483647 - decoded_term_bytes {
        raise @support.SuccinctError::NumericOverflow(
          context="front-coded cumulative term bytes",
        )
      }
      decoded_term_bytes += term.length()
      limits.check_total_terms(decoded_term_bytes)
      match previous {
        Some(value) =>
          if @support.compare_bytes(value, term) >= 0 {
            raise @support.SuccinctError::InvalidSequence(
              index~,
              detail="decoded terms must be strictly increasing",
            )
          }
        None => ()
      }
      previous = Some(term)
    }
    let expected_end = if block + 1 < expected_blocks {
      candidate.block_offsets[block + 1]
    } else {
      candidate.encoded.length()
    }
    if reader.position() != expected_end {
      raise @support.SuccinctError::InvalidEncoding(
        offset=reader.position(),
        context="front-coded block",
        detail="record bytes do not end at the next restart offset",
      )
    }
  }
  candidate
}
