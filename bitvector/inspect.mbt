///|
/// Representation-specific counts used to explain index overhead.
pub(all) struct BitVectorStatistics {
  logical_bits : Int
  one_bits : Int
  zero_bits : Int
  packed_words : Int
  padding_bits : Int
  superblock_entries : Int
  block_entries : Int
} derive(Debug, Eq)

///|
/// Detailed deterministic representation statistics.
pub fn BitVector::statistics(self : BitVector) -> BitVectorStatistics {
  {
    logical_bits: self.length,
    one_bits: self.ones,
    zero_bits: self.length - self.ones,
    packed_words: self.words.length(),
    padding_bits: self.words.length() * word_bits - self.length,
    superblock_entries: self.superblocks.length(),
    block_entries: self.blocks.length(),
  }
}

///|
/// Portable accounting. Payload includes final-word padding; auxiliary bits
/// count the conceptual 32-bit rank directory entries and exclude VM headers.
pub fn BitVector::space_report(
  self : BitVector,
) -> @support.SpaceReport raise @support.SuccinctError {
  let payload_bits = self.words.length().to_int64() * 64L
  let directory_entries = self.superblocks.length() + self.blocks.length()
  let auxiliary_bits = directory_entries.to_int64() * 32L
  @support.SpaceReport::new(
    "rank-select-bitvector",
    self.length,
    payload_bits,
    auxiliary_bits,
    encode(self).length(),
  )
}
