///|
fn BitVector::check_prefix_position(
  self : BitVector,
  position : Int,
) -> Unit raise @support.SuccinctError {
  if position < 0 || position > self.length {
    raise @support.SuccinctError::OutOfRange(
      context="rank prefix",
      index=position,
      length=self.length + 1,
    )
  }
}

///|
fn BitVector::rank1_valid(self : BitVector, position : Int) -> Int {
  if position == 0 {
    return 0
  }
  if position == self.length {
    return self.ones
  }
  let word_index = position / word_bits
  let bit_offset = position % word_bits
  let super_index = word_index / words_per_superblock
  let base = self.superblocks[super_index] + self.blocks[word_index]
  base + popcount_word(self.words[word_index] & low_mask(bit_offset))
}

///|
/// Number of one bits in the half-open prefix [0, position).
pub fn BitVector::rank1(
  self : BitVector,
  position : Int,
) -> Int raise @support.SuccinctError {
  self.check_prefix_position(position)
  self.rank1_valid(position)
}

///|
/// Number of zero bits in the half-open prefix [0, position).
pub fn BitVector::rank0(
  self : BitVector,
  position : Int,
) -> Int raise @support.SuccinctError {
  self.check_prefix_position(position)
  position - self.rank1(position)
}

///|
/// Number of one bits in the checked half-open range [start, end).
pub fn BitVector::rank1_range(
  self : BitVector,
  start : Int,
  end : Int,
) -> Int raise @support.SuccinctError {
  if start < 0 || end < start || end > self.length {
    raise @support.SuccinctError::InvalidArgument(
      context="rank1 range",
      detail="expected 0 <= start <= end <= length",
    )
  }
  self.rank1(end) - self.rank1(start)
}

///|
/// Number of zero bits in the checked half-open range [start, end).
pub fn BitVector::rank0_range(
  self : BitVector,
  start : Int,
  end : Int,
) -> Int raise @support.SuccinctError {
  if start < 0 || end < start || end > self.length {
    raise @support.SuccinctError::InvalidArgument(
      context="rank0 range",
      detail="expected 0 <= start <= end <= length",
    )
  }
  end - start - self.rank1_range(start, end)
}
