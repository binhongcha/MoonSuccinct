///|
test "bit vector statistics expose padding and directory shape" {
  let empty = from_bools([])
  assert_eq(empty.statistics(), {
    logical_bits: 0,
    one_bits: 0,
    zero_bits: 0,
    packed_words: 0,
    padding_bits: 0,
    superblock_entries: 0,
    block_entries: 0,
  })
  let vector = from_bools(patterned_bits(513, 2))
  let stats = vector.statistics()
  assert_eq(stats.logical_bits, 513)
  assert_eq(stats.one_bits + stats.zero_bits, 513)
  assert_eq(stats.packed_words, 9)
  assert_eq(stats.padding_bits, 63)
  assert_eq(stats.superblock_entries, 2)
  assert_eq(stats.block_entries, 9)
}

///|
test "bit vector space report separates payload and rank metadata" {
  let vector = from_bools(patterned_bits(513, 3))
  let report = vector.space_report()
  assert_eq(report.structure, "rank-select-bitvector")
  assert_eq(report.logical_items, 513)
  assert_eq(report.payload_bits, 9L * 64L)
  assert_eq(report.auxiliary_bits, 11L * 32L)
  assert_eq(report.serialized_bytes, encode(vector).length())
  assert_true(report.accounted_bits() > report.payload_bits)
}
