///|
test "stream builder accepts duplicates and freezes snapshots" {
  let builder = EliasFanoBuilder::new()
  assert_true(builder.is_empty())
  builder.push(3UL)
  builder.append_all([3UL, 9UL, 100UL])
  assert_eq(builder.length(), 4)
  assert_eq(builder.last(), Some(100UL))
  assert_eq(builder.to_values(), [3UL, 3UL, 9UL, 100UL])
  let first = builder.finish()
  builder.push(1000UL)
  let second = builder.finish()
  assert_eq(first.to_values(), [3UL, 3UL, 9UL, 100UL])
  assert_eq(second.to_values(), [3UL, 3UL, 9UL, 100UL, 1000UL])
}

///|
test "stream builder rejects descending input without appending it" {
  let builder = EliasFanoBuilder::new()
  builder.append_all([1UL, 5UL, 8UL])
  ignore(builder.push(7UL)) catch {
    @support.SuccinctError::InvalidSequence(index~, ..) => assert_eq(index, 3)
    _ => fail("expected monotonicity error")
  }
  assert_eq(builder.to_values(), [1UL, 5UL, 8UL])
  builder.push(9UL)
  assert_eq(builder.finish().to_values(), [1UL, 5UL, 8UL, 9UL])
}

///|
test "stream builder can be cleared and reused" {
  let builder = EliasFanoBuilder::new()
  builder.append_all([20UL, 21UL])
  builder.clear()
  assert_true(builder.is_empty())
  assert_eq(builder.last(), None)
  assert_eq(builder.finish().to_values(), [])
  builder.append_all([0UL, 0xffffffffffffffffUL])
  assert_eq(builder.finish().to_values(), [0UL, 0xffffffffffffffffUL])
}
