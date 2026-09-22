///|
let bitvector_magic : Bytes = b"MSBV"

///|
let bitvector_format_version : Int = 1

///|
/// Encode the canonical packed words and logical length. Rank directories are
/// derived metadata and are rebuilt by the decoder.
pub fn encode(vector : BitVector) -> Bytes {
  let writer = @binary.Writer::new()
  writer.write_bytes(bitvector_magic)
  writer.write_byte(bitvector_format_version.to_byte())
  writer.write_varint(vector.length.to_uint64())
  writer.write_varint(vector.words.length().to_uint64())
  for word in vector.words {
    writer.write_u64(word)
  }
  writer.finish()
}

///|
/// Decode and validate a canonical bit-vector format.
pub fn decode(
  data : Bytes,
  limits? : @support.DecodeLimits = @support.DecodeLimits::sensible(),
) -> BitVector raise @support.SuccinctError {
  let reader = @binary.Reader::new(data, limits~)
  reader.read_magic(bitvector_magic, "bitvector")
  let version = reader.read_byte(context="bitvector version").to_int()
  if version != bitvector_format_version {
    raise @support.SuccinctError::UnsupportedVersion(
      format="bitvector",
      version~,
    )
  }
  let length = reader.read_count("bit length")
  let word_count = reader.read_count("bit word count")
  let expected = packed_word_count(length)
  if word_count != expected {
    raise @support.SuccinctError::InvalidEncoding(
      offset=reader.position(),
      context="bitvector",
      detail="packed word count does not match logical length",
    )
  }
  let words : Array[UInt64] = []
  for index = 0; index < word_count; index = index + 1 {
    words.push(reader.read_u64(context="packed word"))
  }
  reader.finish("bitvector")
  from_words(words, length)
}
