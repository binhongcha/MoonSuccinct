///|
/// Number of packed bits in one storage word.
pub let word_bits : Int = 64

///|
/// Number of storage words covered by one rank superblock.
pub let words_per_superblock : Int = 8

///|
/// Mutable append-only assembly state. `finish` returns an owned immutable
/// `BitVector` snapshot.
pub struct BitBuilder {
  words : Array[UInt64]
  mut length : Int
  mut ones : Int
}

///|
/// Immutable packed bits with superblock/block rank directories.
pub struct BitVector {
  words : Array[UInt64]
  length : Int
  ones : Int
  superblocks : Array[Int]
  blocks : Array[Int]
}

///|
fn popcount_word(initial : UInt64) -> Int {
  let mut value = initial
  let mut count = 0
  while value != 0UL {
    value = value & (value - 1UL)
    count += 1
  }
  count
}

///|
fn valid_bits_in_word(length : Int, word_index : Int) -> Int {
  let start = word_index * word_bits
  let remaining = length - start
  if remaining <= 0 {
    0
  } else if remaining >= word_bits {
    word_bits
  } else {
    remaining
  }
}

///|
/// Number of storage words for a non-negative logical bit length. Subtracting
/// before dividing avoids overflowing `Int` near its upper bound.
fn packed_word_count(length : Int) -> Int {
  if length <= 0 {
    0
  } else {
    (length - 1) / word_bits + 1
  }
}

///|
fn low_mask(bits : Int) -> UInt64 {
  if bits <= 0 {
    0UL
  } else if bits >= 64 {
    0xffffffffffffffffUL
  } else {
    (1UL << bits) - 1UL
  }
}

///|
fn copy_words(words : Array[UInt64]) -> Array[UInt64] {
  let result : Array[UInt64] = []
  for word in words {
    result.push(word)
  }
  result
}
