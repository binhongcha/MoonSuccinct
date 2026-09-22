///|
/// Immutable fixed-width unsigned integers packed across 64-bit words.
pub struct PackedInts {
  width : Int
  length : Int
  words : Array[UInt64]
}

///|
fn width_mask(width : Int) -> UInt64 {
  if width <= 0 {
    0UL
  } else if width >= 64 {
    0xffffffffffffffffUL
  } else {
    (1UL << width) - 1UL
  }
}

///|
fn required_words(
  length : Int,
  width : Int,
) -> Int raise @support.SuccinctError {
  if length < 0 {
    raise @support.SuccinctError::InvalidArgument(
      context="packed length",
      detail="must be non-negative",
    )
  }
  if width < 0 || width > 64 {
    raise @support.SuccinctError::InvalidArgument(
      context="packed width",
      detail="must be between 0 and 64",
    )
  }
  let bits = length.to_uint64() * width.to_uint64()
  if bits > 2147483647UL {
    raise @support.SuccinctError::ResourceLimit(
      limit="packed_bits",
      actual=bits.reinterpret_as_int64(),
      maximum=2147483647L,
    )
  }
  if bits == 0UL {
    0
  } else {
    ((bits + 63UL) / 64UL).to_int()
  }
}

///|
/// Pack values using exactly width bits each.
pub fn from_values(
  values : Array[UInt64],
  width : Int,
) -> PackedInts raise @support.SuccinctError {
  let word_count = required_words(values.length(), width)
  let words = Array::make(word_count, 0UL)
  let mask = width_mask(width)
  for index = 0; index < values.length(); index = index + 1 {
    let value = values[index]
    if width < 64 && (value & mask) != value {
      raise @support.SuccinctError::InvalidSequence(
        index~,
        detail="value does not fit packed width",
      )
    }
    if width > 0 {
      let bit_position = index * width
      let word_index = bit_position / 64
      let offset = bit_position % 64
      words[word_index] = words[word_index] | (value << offset)
      if offset + width > 64 {
        words[word_index + 1] = words[word_index + 1] | (value >> (64 - offset))
      }
    }
  }
  { width, length: values.length(), words, }
}

///|
/// Rebuild from canonical packed words. Unused final padding must be zero.
pub fn from_words(
  input_words : Array[UInt64],
  length : Int,
  width : Int,
) -> PackedInts raise @support.SuccinctError {
  let expected = required_words(length, width)
  if input_words.length() != expected {
    raise @support.SuccinctError::InvalidArgument(
      context="packed words",
      detail="word count does not match length and width",
    )
  }
  if expected > 0 {
    let used_bits = length * width
    let final_bits = used_bits % 64
    if final_bits != 0 {
      let mask = width_mask(final_bits)
      if (input_words[expected - 1] & mask) != input_words[expected - 1] {
        raise @support.SuccinctError::InvalidArgument(
          context="packed words",
          detail="padding bits in final word must be zero",
        )
      }
    }
  }
  let copied : Array[UInt64] = []
  for word in input_words {
    copied.push(word)
  }
  { width, length, words: copied, }
}

///|
/// Number of packed values.
pub fn PackedInts::length(self : PackedInts) -> Int {
  self.length
}

///|
/// Bit width used by every value.
pub fn PackedInts::width(self : PackedInts) -> Int {
  self.width
}

///|
/// Number of 64-bit storage words.
pub fn PackedInts::word_count(self : PackedInts) -> Int {
  self.words.length()
}

///|
/// Optional indexed access.
pub fn PackedInts::get(self : PackedInts, index : Int) -> UInt64? {
  if index < 0 || index >= self.length {
    return None
  }
  if self.width == 0 {
    return Some(0UL)
  }
  let bit_position = index * self.width
  let word_index = bit_position / 64
  let offset = bit_position % 64
  let mut value = self.words[word_index] >> offset
  if offset + self.width > 64 {
    value = value | (self.words[word_index + 1] << (64 - offset))
  }
  Some(value & width_mask(self.width))
}

///|
/// Checked indexed access.
pub fn PackedInts::at(
  self : PackedInts,
  index : Int,
) -> UInt64 raise @support.SuccinctError {
  match self.get(index) {
    Some(value) => value
    None =>
      raise @support.SuccinctError::OutOfRange(
        context="packed integer",
        index~,
        length=self.length,
      )
  }
}

///|
/// Return an owned copy of packed words.
pub fn PackedInts::packed_words(self : PackedInts) -> Array[UInt64] {
  let copied : Array[UInt64] = []
  for word in self.words {
    copied.push(word)
  }
  copied
}

///|
/// Materialize the logical values.
pub fn PackedInts::to_values(self : PackedInts) -> Array[UInt64] {
  let values : Array[UInt64] = []
  for index = 0; index < self.length; index = index + 1 {
    values.push(self.get(index).unwrap())
  }
  values
}

///|
/// Payload bits including final word padding.
pub fn PackedInts::storage_bits(self : PackedInts) -> Int64 {
  self.words.length().to_int64() * 64L
}

///|
/// Logical value bits before final word padding.
pub fn PackedInts::logical_bits(self : PackedInts) -> Int64 {
  self.length.to_int64() * self.width.to_int64()
}
