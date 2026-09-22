///|
/// Number of represented logical bits.
pub fn BitVector::length(self : BitVector) -> Int {
  self.length
}

///|
/// Whether no logical bits are represented.
pub fn BitVector::is_empty(self : BitVector) -> Bool {
  self.length == 0
}

///|
/// Number of packed 64-bit storage words.
pub fn BitVector::word_count(self : BitVector) -> Int {
  self.words.length()
}

///|
/// Number of represented one bits.
pub fn BitVector::one_count(self : BitVector) -> Int {
  self.ones
}

///|
/// Number of represented zero bits.
pub fn BitVector::zero_count(self : BitVector) -> Int {
  self.length - self.ones
}

///|
/// Safe optional access to one logical bit.
pub fn BitVector::get(self : BitVector, index : Int) -> Bool? {
  if index < 0 || index >= self.length {
    None
  } else {
    Some(((self.words[index / 64] >> (index % 64)) & 1UL) == 1UL)
  }
}

///|
/// Checked access to one logical bit.
pub fn BitVector::bit(
  self : BitVector,
  index : Int,
) -> Bool raise @support.SuccinctError {
  match self.get(index) {
    Some(value) => value
    None =>
      raise @support.SuccinctError::OutOfRange(
        context="bit",
        index~,
        length=self.length,
      )
  }
}

///|
/// Return an owned copy of the canonical packed words.
pub fn BitVector::packed_words(self : BitVector) -> Array[UInt64] {
  copy_words(self.words)
}

///|
/// Return all logical bits as a simple reference representation.
pub fn BitVector::to_bools(self : BitVector) -> Array[Bool] {
  let result : Array[Bool] = []
  for index = 0; index < self.length; index = index + 1 {
    result.push(
      ((self.words[index / word_bits] >> (index % word_bits)) & 1UL) == 1UL,
    )
  }
  result
}
