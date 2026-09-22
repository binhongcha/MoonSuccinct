///|
test "Elias-Fano statistics account for the low and unary high parts" {
  let sequence = from_values([1UL, 2UL, 2UL, 1000UL, 1000000UL])
  let stats = sequence.statistics()
  assert_eq(stats.values, 5)
  assert_eq(stats.low_logical_bits, 5L * stats.low_width.to_int64())
  assert_true(stats.low_storage_bits >= stats.low_logical_bits)
  assert_eq(stats.high_one_bits, 5)
  assert_eq(stats.high_one_bits + stats.high_zero_bits, stats.high_logical_bits)
  assert_true(stats.high_rank_directory_bits > 0L)
}

///|
test "Elias-Fano space report is stable for empty and populated data" {
  let empty = from_values([])
  let empty_report = empty.space_report()
  assert_eq(empty_report.logical_items, 0)
  assert_eq(empty_report.payload_bits, 0L)
  assert_eq(empty_report.auxiliary_bits, 0L)
  assert_eq(empty_report.serialized_bytes, encode(empty).length())
  let sequence = from_values(generated_monotone(500, 5))
  let report = sequence.space_report()
  assert_eq(report.structure, "elias-fano")
  assert_eq(report.logical_items, 500)
  assert_true(report.payload_bits > 0L)
  assert_true(report.serialized_bytes > 0)
}
