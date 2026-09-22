///|
test "half-open value ranges preserve duplicate positions" {
  let sequence = from_values([1UL, 2UL, 2UL, 2UL, 4UL, 8UL, 8UL, 16UL])
  assert_eq(sequence.range(2UL, 8UL), { start: 1, end: 5, })
  assert_eq(sequence.count_range(2UL, 8UL), 4)
  assert_eq(sequence.values_in_range(2UL, 9UL, 20), [
    2UL, 2UL, 2UL, 4UL, 8UL, 8UL,
  ])
  assert_eq(sequence.values_in_range(2UL, 9UL, 2), [2UL, 2UL])
  assert_eq(sequence.values_in_range(3UL, 4UL, 10), [])
  assert_eq(sequence.values_in_range(0UL, 100UL, 0), [])
}

///|
test "indexed slices are owned valid encodings" {
  let sequence = from_values([0UL, 3UL, 3UL, 10UL, 1000UL])
  let middle = sequence.slice(1, 4)
  assert_eq(middle.to_values(), [3UL, 3UL, 10UL])
  assert_eq(decode(encode(middle)).to_values(), [3UL, 3UL, 10UL])
  assert_eq(sequence.slice(0, 0).to_values(), [])
  assert_eq(sequence.slice(5, 5).to_values(), [])
}

///|
test "range and slice reject invalid bounds" {
  let sequence = from_values([1UL, 2UL])
  ignore(sequence.range(3UL, 2UL)) catch {
    @support.SuccinctError::InvalidArgument(..) => ()
    _ => fail("expected reversed value range error")
  }
  ignore(sequence.values_in_range(0UL, 3UL, -1)) catch {
    @support.SuccinctError::InvalidArgument(..) => ()
    _ => fail("expected negative limit error")
  }
  ignore(sequence.slice(-1, 1)) catch {
    @support.SuccinctError::OutOfRange(..) => ()
    _ => fail("expected slice start error")
  }
  ignore(sequence.slice(2, 1)) catch {
    @support.SuccinctError::InvalidArgument(..) => ()
    _ => fail("expected slice end error")
  }
}

///|
test "distinct set operations define duplicate semantics" {
  let left = from_values([1UL, 1UL, 2UL, 4UL, 8UL, 8UL, 10UL])
  let right = from_values([0UL, 2UL, 2UL, 3UL, 8UL, 12UL])
  assert_eq(intersect_distinct(left, right).to_values(), [2UL, 8UL])
  assert_eq(union_distinct(left, right).to_values(), [
    0UL, 1UL, 2UL, 3UL, 4UL, 8UL, 10UL, 12UL,
  ])
  assert_eq(difference_distinct(left, right).to_values(), [1UL, 4UL, 10UL])
  assert_eq(difference_distinct(right, left).to_values(), [0UL, 3UL, 12UL])
}

///|
test "distinct set operations handle empty and extreme inputs" {
  let empty = from_values([])
  let all = from_values([0UL, 0UL, 1UL, 0xffffffffffffffffUL])
  assert_eq(intersect_distinct(empty, all).to_values(), [])
  assert_eq(union_distinct(empty, all).to_values(), [
    0UL, 1UL, 0xffffffffffffffffUL,
  ])
  assert_eq(difference_distinct(all, empty).to_values(), [
    0UL, 1UL, 0xffffffffffffffffUL,
  ])
  assert_eq(difference_distinct(all, all).to_values(), [])
}

///|
test "set operations agree with simple generated membership" {
  let left_values : Array[UInt64] = []
  let right_values : Array[UInt64] = []
  for value = 0; value < 200; value = value + 1 {
    if value % 3 == 0 || value % 11 == 0 {
      left_values.push(value.to_uint64())
      if value % 10 == 0 {
        left_values.push(value.to_uint64())
      }
    }
    if value % 5 == 0 || value % 7 == 0 {
      right_values.push(value.to_uint64())
    }
  }
  let left = from_values(left_values)
  let right = from_values(right_values)
  let intersection = intersect_distinct(left, right)
  let union = union_distinct(left, right)
  let difference = difference_distinct(left, right)
  for value = 0; value < 200; value = value + 1 {
    let item = value.to_uint64()
    assert_eq(
      intersection.contains(item),
      left.contains(item) && right.contains(item),
    )
    assert_eq(union.contains(item), left.contains(item) || right.contains(item))
    assert_eq(
      difference.contains(item),
      left.contains(item) && !right.contains(item),
    )
  }
}
