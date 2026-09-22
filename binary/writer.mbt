///|
/// Append-only deterministic little-endian binary writer.
pub struct Writer {
  output : Array[Byte]
}

///|
/// Create an empty writer.
pub fn Writer::new() -> Writer {
  { output: [], }
}

///|
/// Current encoded byte length.
pub fn Writer::length(self : Writer) -> Int {
  self.output.length()
}

///|
/// Append one raw byte.
pub fn Writer::write_byte(self : Writer, value : Byte) -> Unit {
  self.output.push(value)
}

///|
/// Append caller bytes unchanged.
pub fn Writer::write_bytes(self : Writer, value : Bytes) -> Unit {
  for byte in value {
    self.output.push(byte)
  }
}

///|
/// Append a 32-bit unsigned integer in little-endian order.
pub fn Writer::write_u32(self : Writer, value : UInt) -> Unit {
  for shift = 0; shift < 32; shift = shift + 8 {
    self.output.push(((value >> shift) & 0xffU).reinterpret_as_int().to_byte())
  }
}

///|
/// Append a 64-bit unsigned integer in little-endian order.
pub fn Writer::write_u64(self : Writer, value : UInt64) -> Unit {
  for shift = 0; shift < 64; shift = shift + 8 {
    self.output.push(((value >> shift) & 0xffUL).to_int().to_byte())
  }
}

///|
/// Append a canonical unsigned LEB128 integer.
pub fn Writer::write_varint(self : Writer, initial : UInt64) -> Unit {
  let mut value = initial
  while value >= 0x80UL {
    self.output.push(((value & 0x7fUL).to_int() | 0x80).to_byte())
    value = value >> 7
  }
  self.output.push(value.to_int().to_byte())
}

///|
/// Append a byte string preceded by its canonical varint length.
pub fn Writer::write_length_prefixed(self : Writer, value : Bytes) -> Unit {
  self.write_varint(value.length().to_uint64())
  self.write_bytes(value)
}

///|
/// Return an owned immutable byte snapshot.
pub fn Writer::finish(self : Writer) -> Bytes {
  let result : Array[Byte] = []
  for byte in self.output {
    result.push(byte)
  }
  Bytes::from_array(result)
}

///|
/// Number of bytes in the canonical unsigned LEB128 representation.
pub fn varint_length(initial : UInt64) -> Int {
  let mut value = initial
  let mut length = 1
  while value >= 0x80UL {
    value = value >> 7
    length += 1
  }
  length
}
