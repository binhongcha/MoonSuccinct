///|
test "galloping seek agrees with a linear reference across duplicate values" {
  let values = [0UL, 1UL, 1UL, 1UL, 4UL, 9UL, 9UL, 50UL, 1000UL]
  let sequence = from_values(values)
  for start = 0; start <= values.length(); start = start + 1 {
    for target = 0; target < 55; target = target + 1 {
      let mut expected = start
      while expected < values.length() && values[expected] < target.to_uint64() {
        expected += 1
      }
      assert_eq(sequence.lower_bound_from(start, target.to_uint64()), expected)
    }
  }
  assert_eq(sequence.lower_bound_from(0, 1001UL), values.length())
}

///|
test "galloping seek validates start and handles empty sequences" {
  let empty = from_values([])
  assert_eq(empty.lower_bound_from(0, 10UL), 0)
  let sequence = from_values([1UL, 2UL])
  let extreme = from_values([0UL, 0xffffffffffffffffUL])
  assert_eq(extreme.lower_bound_from(0, 0xffffffffffffffffUL), 1)
  assert_eq(extreme.lower_bound_from(1, 0xffffffffffffffffUL), 1)
  ignore(sequence.lower_bound_from(-1, 1UL)) catch {
    @support.SuccinctError::OutOfRange(..) => ()
    _ => fail("expected out-of-range start")
  }
  ignore(sequence.lower_bound_from(3, 1UL)) catch {
    @support.SuccinctError::OutOfRange(..) => ()
    _ => fail("expected out-of-range start")
  }
}
