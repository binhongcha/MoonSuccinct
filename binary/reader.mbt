///|
/// Bounded cursor over immutable encoded bytes.
pub struct Reader {
  data : Bytes
  mut cursor : Int
  mut term_bytes : Int
  limits : @support.DecodeLimits
}

///|
/// Create a reader after enforcing the total input limit.
pub fn Reader::new(
  data : Bytes,
  limits? : @support.DecodeLimits = @support.DecodeLimits::sensible(),
) -> Reader raise @support.SuccinctError {
  limits.check_input(data.length())
  { data, cursor: 0, term_bytes: 0, limits, }
}

///|
/// Current byte offset.
pub fn Reader::position(self : Reader) -> Int {
  self.cursor
}

///|
/// Bytes not yet consumed.
pub fn Reader::remaining(self : Reader) -> Int {
  self.data.length() - self.cursor
}

///|
/// Advance by a validated raw byte count.
pub fn Reader::skip(
  self : Reader,
  count : Int,
  context? : String = "bytes",
) -> Unit raise @support.SuccinctError {
  self.require(count, context)
  self.cursor += count
}

///|
fn Reader::require(
  self : Reader,
  count : Int,
  context : String,
) -> Unit raise @support.SuccinctError {
  if count < 0 {
    raise @support.SuccinctError::InvalidArgument(
      context="read count",
      detail="must be non-negative",
    )
  }
  if count > self.remaining() {
    raise @support.SuccinctError::TruncatedInput(offset=self.cursor, context~)
  }
}

///|
/// Read one raw byte.
pub fn Reader::read_byte(
  self : Reader,
  context? : String = "byte",
) -> Byte raise @support.SuccinctError {
  self.require(1, context)
  let value = self.data[self.cursor]
  self.cursor += 1
  value
}

///|
/// Read a little-endian 32-bit unsigned integer.
pub fn Reader::read_u32(
  self : Reader,
  context? : String = "u32",
) -> UInt raise @support.SuccinctError {
  self.require(4, context)
  let start = self.cursor
  self.cursor += 4
  self.data[start].to_uint() |
  (self.data[start + 1].to_uint() << 8) |
  (self.data[start + 2].to_uint() << 16) |
  (self.data[start + 3].to_uint() << 24)
}

///|
/// Read a little-endian 64-bit unsigned integer.
pub fn Reader::read_u64(
  self : Reader,
  context? : String = "u64",
) -> UInt64 raise @support.SuccinctError {
  self.require(8, context)
  let start = self.cursor
  self.cursor += 8
  let mut value = 0UL
  for index = 0; index < 8; index = index + 1 {
    value = value | (self.data[start + index].to_uint64() << (index * 8))
  }
  value
}

///|
/// Read exactly count bytes into newly owned storage.
pub fn Reader::read_bytes(
  self : Reader,
  count : Int,
  context? : String = "bytes",
) -> Bytes raise @support.SuccinctError {
  self.require(count, context)
  let output : Array[Byte] = []
  for index = 0; index < count; index = index + 1 {
    output.push(self.data[self.cursor + index])
  }
  self.cursor += count
  Bytes::from_array(output)
}

///|
/// Read and compare fixed magic bytes.
pub fn Reader::read_magic(
  self : Reader,
  expected : Bytes,
  context : String,
) -> Unit raise @support.SuccinctError {
  let offset = self.cursor
  let actual = self.read_bytes(expected.length(), context~)
  if actual != expected {
    raise @support.SuccinctError::InvalidEncoding(
      offset~,
      context~,
      detail="magic bytes do not match",
    )
  }
}

///|
/// Read a canonical unsigned LEB128 integer.
pub fn Reader::read_varint(
  self : Reader,
  context? : String = "varint",
) -> UInt64 raise @support.SuccinctError {
  let start = self.cursor
  let mut value = 0UL
  let mut shift = 0
  while shift < 70 {
    if self.remaining() == 0 {
      raise @support.SuccinctError::TruncatedInput(offset=self.cursor, context~)
    }
    let byte = self.read_byte(context~)
    let payload = (byte.to_int() & 0x7f).to_uint64()
    if shift == 63 && payload > 1UL {
      raise @support.SuccinctError::NumericOverflow(context~)
    }
    value = value | (payload << shift)
    if (byte.to_int() & 0x80) == 0 {
      if self.cursor - start != varint_length(value) {
        raise @support.SuccinctError::InvalidEncoding(
          offset=start,
          context~,
          detail="non-canonical varint",
        )
      }
      return value
    }
    shift += 7
  }
  raise @support.SuccinctError::NumericOverflow(context~)
}

///|
/// Read a varint length after enforcing Int and caller resource limits.
pub fn Reader::read_count(
  self : Reader,
  context : String,
) -> Int raise @support.SuccinctError {
  let value = self.read_varint(context~)
  if value > 2147483647UL {
    raise @support.SuccinctError::NumericOverflow(context~)
  }
  let count = value.to_int()
  self.limits.check_items(count)
  count
}

///|
/// Read a length-prefixed term under per-term and cumulative caller checks.
pub fn Reader::read_term(
  self : Reader,
  context : String,
) -> Bytes raise @support.SuccinctError {
  let value = self.read_varint(context="\{context} length")
  if value > 2147483647UL {
    raise @support.SuccinctError::NumericOverflow(context~)
  }
  let count = value.to_int()
  self.limits.check_term(count)
  let next_total = self.term_bytes + count
  self.limits.check_total_terms(next_total)
  let result = self.read_bytes(count, context~)
  self.term_bytes = next_total
  result
}

///|
/// Reject unconsumed trailing bytes.
pub fn Reader::finish(
  self : Reader,
  context : String,
) -> Unit raise @support.SuccinctError {
  if self.remaining() != 0 {
    raise @support.SuccinctError::InvalidEncoding(
      offset=self.cursor,
      context~,
      detail="trailing bytes",
    )
  }
}
