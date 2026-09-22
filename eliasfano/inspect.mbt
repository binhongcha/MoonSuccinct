///|
/// Deterministic representation statistics for one Elias–Fano sequence.
pub(all) struct EliasFanoStatistics {
  values : Int
  low_width : Int
  low_logical_bits : Int64
  low_storage_bits : Int64
  high_logical_bits : Int
  high_one_bits : Int
  high_zero_bits : Int
  high_rank_directory_bits : Int64
} derive(Debug, Eq)

///|
/// Inspect the low/high split and derived rank overhead.
pub fn EliasFano::statistics(self : EliasFano) -> EliasFanoStatistics {
  let high = self.highs.statistics()
  {
    values: self.length,
    low_width: self.low_width,
    low_logical_bits: self.lows.logical_bits(),
    low_storage_bits: self.lows.storage_bits(),
    high_logical_bits: high.logical_bits,
    high_one_bits: high.one_bits,
    high_zero_bits: high.zero_bits,
    high_rank_directory_bits: (high.superblock_entries + high.block_entries).to_int64() *
    32L,
  }
}

///|
/// Portable space accounting excluding runtime object headers.
pub fn EliasFano::space_report(
  self : EliasFano,
) -> @support.SpaceReport raise @support.SuccinctError {
  let stats = self.statistics()
  let high_storage_bits = self.highs.word_count().to_int64() * 64L
  @support.SpaceReport::new(
    "elias-fano",
    self.length,
    stats.low_storage_bits + high_storage_bits,
    stats.high_rank_directory_bits,
    encode(self).length(),
  )
}
