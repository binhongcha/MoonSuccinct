///|
test "skewed intersection agrees with merge for duplicates and sparse gaps" {
  let dense_values : Array[UInt64] = []
  for value = 0; value < 500; value = value + 1 {
    dense_values.push(value.to_uint64())
  }
  let dense = from_values(dense_values)
  let sparse = from_values([0UL, 0UL, 17UL, 250UL, 250UL, 499UL, 900UL])
  let expected = [0UL, 17UL, 250UL, 499UL]
  assert_eq(intersect_distinct_skewed(sparse, dense).to_values(), expected)
  assert_eq(intersect_distinct_skewed(dense, sparse).to_values(), expected)
  assert_eq(
    intersect_distinct_skewed(sparse, dense).to_values(),
    intersect_distinct(sparse, dense).to_values(),
  )
  assert_eq(intersect_distinct_skewed(from_values([]), dense).to_values(), [])
}
