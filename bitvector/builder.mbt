///|
/// Create an empty append-only bit builder.
pub fn BitBuilder::new() -> BitBuilder {
  { words: [], length: 0, ones: 0, }
}

///|
/// Current number of appended logical bits.
pub fn BitBuilder::length(self : BitBuilder) -> Int {
  self.length
}

///|
/// Current number of appended one bits.
pub fn BitBuilder::one_count(self : BitBuilder) -> Int {
  self.ones
}

///|
/// Append one logical bit.
pub fn BitBuilder::push(self : BitBuilder, bit : Bool) -> Unit {
  let bit_offset = self.length % word_bits
  if bit_offset == 0 {
    self.words.push(0UL)
  }
  if bit {
    let word_index = self.words.length() - 1
    self.words[word_index] = self.words[word_index] | (1UL << bit_offset)
    self.ones += 1
  }
  self.length += 1
}

///|
/// Append `count` copies of one bit.
pub fn BitBuilder::push_repeated(
  self : BitBuilder,
  bit : Bool,
  count : Int,
) -> Unit raise @support.SuccinctError {
  if count < 0 {
    raise @support.SuccinctError::InvalidArgument(
      context="bit repeat count",
      detail="must be non-negative",
    )
  }
  for i = 0; i < count; i = i + 1 {
    self.push(bit)
  }
}

///|
/// Append all bits from an array.
pub fn BitBuilder::append_all(self : BitBuilder, bits : Array[Bool]) -> Unit {
  for bit in bits {
    self.push(bit)
  }
}

///|
/// Freeze an owned immutable snapshot. Later builder mutations cannot change
/// the returned vector.
pub fn BitBuilder::finish(self : BitBuilder) -> BitVector {
  let words = copy_words(self.words)
  let superblocks : Array[Int] = []
  let blocks : Array[Int] = []
  let mut total = 0
  let mut within_superblock = 0
  for word_index = 0; word_index < words.length(); word_index = word_index + 1 {
    if word_index % words_per_superblock == 0 {
      superblocks.push(total)
      within_superblock = 0
    }
    blocks.push(within_superblock)
    let valid = valid_bits_in_word(self.length, word_index)
    let count = popcount_word(words[word_index] & low_mask(valid))
    total += count
    within_superblock += count
  }
  { words, length: self.length, ones: total, superblocks, blocks, }
}

///|
/// Build a vector from caller-supplied logical bits.
pub fn from_bools(bits : Array[Bool]) -> BitVector {
  let builder = BitBuilder::new()
  builder.append_all(bits)
  builder.finish()
}

///|
/// Build a vector from packed words. Bits at and above `length` in the final
/// word must be zero, which prevents hidden data from changing serialization.
pub fn from_words(
  input_words : Array[UInt64],
  length : Int,
) -> BitVector raise @support.SuccinctError {
  if length < 0 {
    raise @support.SuccinctError::InvalidArgument(
      context="bit length",
      detail="must be non-negative",
    )
  }
  let expected_words = if length == 0 { 0 } else { (length + 63) / 64 }
  if input_words.length() != expected_words {
    raise @support.SuccinctError::InvalidArgument(
      context="packed words",
      detail="word count does not match logical length",
    )
  }
  if expected_words > 0 {
    let final_bits = valid_bits_in_word(length, expected_words - 1)
    if (input_words[expected_words - 1] & low_mask(final_bits)) !=
      input_words[expected_words - 1] {
      raise @support.SuccinctError::InvalidArgument(
        context="packed words",
        detail="padding bits in final word must be zero",
      )
    }
  }
  let builder = BitBuilder::new()
  for index = 0; index < length; index = index + 1 {
    let word = input_words[index / 64]
    builder.push(((word >> (index % 64)) & 1UL) == 1UL)
  }
  builder.finish()
}
