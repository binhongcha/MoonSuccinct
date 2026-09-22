///|
let dictionary_magic : Bytes = b"MSFD"

///|
let dictionary_version : Int = 1

///|
/// Encode dictionary records and restart offsets deterministically.
pub fn encode(dictionary : Dictionary) -> Bytes {
  let writer = @binary.Writer::new()
  writer.write_bytes(dictionary_magic)
  writer.write_byte(dictionary_version.to_byte())
  writer.write_varint(dictionary.terms.to_uint64())
  writer.write_varint(dictionary.block_size.to_uint64())
  writer.write_length_prefixed(dictionary.encoded)
  writer.write_varint(dictionary.block_offsets.length().to_uint64())
  for offset in dictionary.block_offsets {
    writer.write_varint(offset.to_uint64())
  }
  writer.finish()
}

///|
/// Decode and fully validate a front-coded dictionary.
pub fn decode(
  data : Bytes,
  limits? : @support.DecodeLimits = @support.DecodeLimits::sensible(),
) -> Dictionary raise @support.SuccinctError {
  let reader = @binary.Reader::new(data, limits~)
  reader.read_magic(dictionary_magic, "front-coded dictionary")
  let version = reader
    .read_byte(context="front-coded dictionary version")
    .to_int()
  if version != dictionary_version {
    raise @support.SuccinctError::UnsupportedVersion(
      format="front-coded dictionary",
      version~,
    )
  }
  let terms = reader.read_count("front-coded term count")
  let block_size64 = reader.read_varint(context="front-coded block size")
  if block_size64 == 0UL || block_size64 > 2147483647UL {
    raise @support.SuccinctError::InvalidEncoding(
      offset=reader.position(),
      context="front-coded dictionary",
      detail="block size must be positive and fit Int",
    )
  }
  let encoded_length64 = reader.read_varint(context="front-coded data length")
  if encoded_length64 > 2147483647UL {
    raise @support.SuccinctError::NumericOverflow(
      context="front-coded data length",
    )
  }
  let encoded = reader.read_bytes(
    encoded_length64.to_int(),
    context="front-coded data",
  )
  let offset_count = reader.read_count("front-coded offset count")
  let offsets : Array[Int] = []
  for index = 0; index < offset_count; index = index + 1 {
    let offset64 = reader.read_varint(context="front-coded block offset")
    if offset64 > 2147483647UL {
      raise @support.SuccinctError::NumericOverflow(
        context="front-coded block offset",
      )
    }
    offsets.push(offset64.to_int())
  }
  reader.finish("front-coded dictionary")
  from_parts(terms, block_size64.to_int(), encoded, offsets, limits~)
}
