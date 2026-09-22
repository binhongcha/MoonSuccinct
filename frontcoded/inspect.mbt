///|
/// Representation statistics for a front-coded dictionary.
pub(all) struct DictionaryStatistics {
  terms : Int
  blocks : Int
  block_size : Int
  encoded_record_bytes : Int
  restart_offset_bytes : Int
} derive(Debug, Eq)

///|
/// Inspect record and restart-index sizes separately.
pub fn Dictionary::statistics(self : Dictionary) -> DictionaryStatistics {
  {
    terms: self.terms,
    blocks: self.block_offsets.length(),
    block_size: self.block_size,
    encoded_record_bytes: self.encoded.length(),
    restart_offset_bytes: self.block_offsets.length() * 4,
  }
}

///|
/// Portable space accounting excluding runtime collection headers.
pub fn Dictionary::space_report(
  self : Dictionary,
) -> @support.SpaceReport raise @support.SuccinctError {
  @support.SpaceReport::new(
    "front-coded-dictionary",
    self.terms,
    self.encoded.length().to_int64() * 8L,
    self.block_offsets.length().to_int64() * 32L,
    encode(self).length(),
  )
}
