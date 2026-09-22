///|
let elias_fano_magic : Bytes = b"MSEF"

///|
let elias_fano_version : Int = 1

///|
/// Encode stable Elias–Fano parts without derived rank directories.
pub fn encode(sequence : EliasFano) -> Bytes {
  let writer = @binary.Writer::new()
  writer.write_bytes(elias_fano_magic)
  writer.write_byte(elias_fano_version.to_byte())
  writer.write_varint(sequence.length.to_uint64())
  match sequence.maximum {
    None => writer.write_byte(0)
    Some(maximum) => {
      writer.write_byte(1)
      writer.write_u64(maximum)
    }
  }
  writer.write_byte(sequence.low_width.to_byte())
  let low_words = sequence.lows.packed_words()
  writer.write_varint(low_words.length().to_uint64())
  for word in low_words {
    writer.write_u64(word)
  }
  writer.write_varint(sequence.highs.length().to_uint64())
  let high_words = sequence.highs.packed_words()
  writer.write_varint(high_words.length().to_uint64())
  for word in high_words {
    writer.write_u64(word)
  }
  writer.finish()
}

///|
/// Decode and validate a stable Elias–Fano representation.
pub fn decode(
  data : Bytes,
  limits? : @support.DecodeLimits = @support.DecodeLimits::sensible(),
) -> EliasFano raise @support.SuccinctError {
  let reader = @binary.Reader::new(data, limits~)
  reader.read_magic(elias_fano_magic, "Elias-Fano")
  let version = reader.read_byte(context="Elias-Fano version").to_int()
  if version != elias_fano_version {
    raise @support.SuccinctError::UnsupportedVersion(
      format="Elias-Fano",
      version~,
    )
  }
  let length = reader.read_count("Elias-Fano length")
  let maximum = match
    reader.read_byte(context="Elias-Fano maximum flag").to_int() {
    0 => None
    1 => Some(reader.read_u64(context="Elias-Fano maximum"))
    flag =>
      raise @support.SuccinctError::InvalidEncoding(
        offset=reader.position() - 1,
        context="Elias-Fano",
        detail="invalid maximum flag \{flag}",
      )
  }
  let low_width = reader.read_byte(context="Elias-Fano low width").to_int()
  let low_word_count = reader.read_count("Elias-Fano low word count")
  let low_bits = length.to_uint64() * low_width.to_uint64()
  let expected_low = if low_bits == 0UL {
    0UL
  } else {
    (low_bits + 63UL) / 64UL
  }
  if low_width > 63 || low_word_count.to_uint64() != expected_low {
    raise @support.SuccinctError::InvalidEncoding(
      offset=reader.position(),
      context="Elias-Fano",
      detail="low width or word count is inconsistent",
    )
  }
  let low_words : Array[UInt64] = []
  for index = 0; index < low_word_count; index = index + 1 {
    low_words.push(reader.read_u64(context="Elias-Fano low word"))
  }
  let high_length = reader.read_count("Elias-Fano high bit length")
  let high_word_count = reader.read_count("Elias-Fano high word count")
  let expected_high = if high_length == 0 {
    0
  } else {
    (high_length - 1) / 64 + 1
  }
  if high_word_count != expected_high {
    raise @support.SuccinctError::InvalidEncoding(
      offset=reader.position(),
      context="Elias-Fano",
      detail="high word count is inconsistent",
    )
  }
  let high_words : Array[UInt64] = []
  for index = 0; index < high_word_count; index = index + 1 {
    high_words.push(reader.read_u64(context="Elias-Fano high word"))
  }
  reader.finish("Elias-Fano")
  from_parts(length, maximum, low_width, low_words, high_words, high_length)
}
