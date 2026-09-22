///|
test "Elias-Fano reconstructs dense sparse duplicate and extreme values" {
  let cases : Array[Array[UInt64]] = [
    [],
    [0UL],
    [7UL],
    [0UL, 1UL, 2UL, 3UL, 4UL],
    [5UL, 5UL, 5UL, 5UL],
    [1UL, 1000UL, 1000000UL, 1000000000UL],
    [0xffffffffffffffffUL],
  ]
  for values in cases {
    let encoded = from_values(values)
    assert_eq(encoded.length(), values.length())
    assert_eq(encoded.to_values(), values)
    if values.length() == 0 {
      assert_true(encoded.is_empty())
      assert_eq(encoded.minimum(), None)
      assert_eq(encoded.maximum(), None)
    } else {
      assert_eq(encoded.minimum(), Some(values[0]))
      assert_eq(encoded.maximum(), Some(values[values.length() - 1]))
    }
  }
}

///|
test "Elias-Fano rejects a descending pair" {
  ignore(from_values([1UL, 3UL, 2UL, 9UL])) catch {
    @support.SuccinctError::InvalidSequence(index~, ..) => assert_eq(index, 2)
    _ => fail("expected monotonicity error")
  }
}

///|
test "Elias-Fano access is checked" {
  let encoded = from_values([2UL, 2UL, 9UL])
  assert_eq(encoded.get(-1), None)
  assert_eq(encoded.get(0), Some(2UL))
  assert_eq(encoded.get(2), Some(9UL))
  assert_eq(encoded.get(3), None)
  ignore(encoded.at(3)) catch {
    @support.SuccinctError::OutOfRange(..) => ()
    _ => fail("expected range error")
  }
}
