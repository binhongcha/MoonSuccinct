///|
test "dictionary reports encoded records and restart offsets separately" {
  let dictionary = from_terms(
    [b"alpha", b"alphabet", b"alpine", b"beta", b"better"],
    block_size=2,
  )
  let stats = dictionary.statistics()
  assert_eq(stats.terms, 5)
  assert_eq(stats.blocks, 3)
  assert_eq(stats.block_size, 2)
  assert_eq(stats.encoded_record_bytes, dictionary.encoded_bytes())
  assert_eq(stats.restart_offset_bytes, 12)
  let report = dictionary.space_report()
  assert_eq(report.structure, "front-coded-dictionary")
  assert_eq(report.logical_items, 5)
  assert_eq(report.payload_bits, stats.encoded_record_bytes.to_int64() * 8L)
  assert_eq(report.auxiliary_bits, 96L)
}
