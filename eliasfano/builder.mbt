///|
fn validate_monotone(
  values : Array[UInt64],
) -> Unit raise @support.SuccinctError {
  for index = 1; index < values.length(); index = index + 1 {
    if values[index] < values[index - 1] {
      raise @support.SuccinctError::InvalidSequence(
        index~,
        detail="Elias-Fano input must be monotone non-decreasing",
      )
    }
  }
}

///|
/// Build an immutable Elias–Fano sequence from monotone caller values.
pub fn from_values(
  values : Array[UInt64],
) -> EliasFano raise @support.SuccinctError {
  validate_monotone(values)
  if values.length() == 0 {
    return {
      length: 0,
      maximum: None,
      low_width: 0,
      lows: @packed.from_values([], 0),
      highs: @bitvector.from_bools([]),
    }
  }
  let maximum = values[values.length() - 1]
  let low_width = low_width_for(maximum, values.length())
  let mask = low_mask(low_width)
  let low_values : Array[UInt64] = []
  let high_builder = @bitvector.BitBuilder::new()
  let mut high_length = 0
  for index = 0; index < values.length(); index = index + 1 {
    let value = values[index]
    low_values.push(value & mask)
    let high = value >> low_width
    let position = high + index.to_uint64()
    if position > 2147483646UL {
      raise @support.SuccinctError::ResourceLimit(
        limit="elias_fano_high_bits",
        actual=(position + 1UL).reinterpret_as_int64(),
        maximum=2147483647L,
      )
    }
    let position_int = position.to_int()
    high_builder.push_repeated(false, position_int - high_length)
    high_builder.push(true)
    high_length = position_int + 1
  }
  {
    length: values.length(),
    maximum: Some(maximum),
    low_width,
    lows: @packed.from_values(low_values, low_width),
    highs: high_builder.finish(),
  }
}

///|
/// Internal reconstruction used by the validated binary decoder.
pub fn from_parts(
  length : Int,
  maximum : UInt64?,
  low_width : Int,
  low_words : Array[UInt64],
  high_words : Array[UInt64],
  high_length : Int,
) -> EliasFano raise @support.SuccinctError {
  if length < 0 {
    raise @support.SuccinctError::InvalidArgument(
      context="Elias-Fano length",
      detail="must be non-negative",
    )
  }
  if low_width < 0 || low_width > 63 {
    raise @support.SuccinctError::InvalidArgument(
      context="Elias-Fano low width",
      detail="must be between 0 and 63",
    )
  }
  let lows = @packed.from_words(low_words, length, low_width)
  let highs = @bitvector.from_words(high_words, high_length)
  if highs.one_count() != length {
    raise @support.SuccinctError::InvalidArgument(
      context="Elias-Fano highs",
      detail="one count must equal sequence length",
    )
  }
  if length == 0 && maximum is Some(_) {
    raise @support.SuccinctError::InvalidArgument(
      context="Elias-Fano maximum",
      detail="empty sequence must not carry a maximum",
    )
  }
  if length > 0 && maximum is None {
    raise @support.SuccinctError::InvalidArgument(
      context="Elias-Fano maximum",
      detail="non-empty sequence must carry a maximum",
    )
  }
  let candidate = { length, maximum, low_width, lows, highs, }
  let values = candidate.to_values()
  validate_monotone(values)
  if length > 0 && values[length - 1] != maximum.unwrap() {
    raise @support.SuccinctError::InvalidArgument(
      context="Elias-Fano maximum",
      detail="stored maximum does not match reconstructed sequence",
    )
  }
  candidate
}
