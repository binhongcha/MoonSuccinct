///|
fn naive_next(bits : Array[Bool], from : Int, target : Bool) -> Int? {
  let mut index = from
  while index < bits.length() {
    if bits[index] == target {
      return Some(index)
    }
    index += 1
  }
  None
}

///|
fn naive_previous(bits : Array[Bool], position : Int, target : Bool) -> Int? {
  if position <= 0 || bits.length() == 0 {
    return None
  }
  let mut index = position - 1
  while index >= 0 {
    if bits[index] == target {
      return Some(index)
    }
    index -= 1
  }
  None
}

///|
test "next and previous navigation handles boundaries" {
  let vector = from_bools([false, true, false, false, true, true, false])
  ignore(vector.next1(-1)) catch {
    @support.SuccinctError::OutOfRange(..) => ()
    _ => fail("expected navigation range error")
  }
  assert_eq(vector.next1(1), Some(1))
  assert_eq(vector.next1(2), Some(4))
  assert_eq(vector.next1(6), None)
  assert_eq(vector.next1(7), None)
  assert_eq(vector.next0(0), Some(0))
  assert_eq(vector.next0(4), Some(6))
  assert_eq(vector.previous1(0), None)
  assert_eq(vector.previous1(4), Some(1))
  assert_eq(vector.previous1(7), Some(5))
  assert_eq(vector.previous0(0), None)
  assert_eq(vector.previous0(5), Some(3))
  assert_eq(vector.previous0(7), Some(6))
}

///|
test "navigation agrees with a linear reference on varied lengths" {
  for length = 0; length <= 260; length = length + 1 {
    let bits : Array[Bool] = []
    for index = 0; index < length; index = index + 1 {
      bits.push((index * 17 + length * 13) % 11 < 4)
    }
    let vector = from_bools(bits)
    for position = 0; position <= length; position = position + 1 {
      assert_eq(vector.next1(position), naive_next(bits, position, true))
      assert_eq(vector.next0(position), naive_next(bits, position, false))
      assert_eq(
        vector.previous1(position),
        naive_previous(bits, position, true),
      )
      assert_eq(
        vector.previous0(position),
        naive_previous(bits, position, false),
      )
    }
  }
}

///|
test "range counts and sparse position materialization agree" {
  let bits = [true, false, true, true, false, false, true, false, true]
  let vector = from_bools(bits)
  assert_eq(vector.ones_in(0, 9), 5)
  assert_eq(vector.zeros_in(0, 9), 4)
  assert_eq(vector.ones_in(2, 7), 3)
  assert_eq(vector.zeros_in(2, 7), 2)
  assert_eq(vector.one_positions(2, 8), [2, 3, 6])
  assert_eq(vector.zero_positions(2, 8), [4, 5, 7])
  assert_eq(vector.one_positions(4, 4), [])
}

///|
test "range APIs reject invalid bounds" {
  let vector = from_bools([true, false])
  ignore(vector.ones_in(-1, 1)) catch {
    @support.SuccinctError::OutOfRange(..) => ()
    _ => fail("expected start range error")
  }
  ignore(vector.zeros_in(2, 1)) catch {
    @support.SuccinctError::InvalidArgument(..) => ()
    _ => fail("expected reversed range error")
  }
  ignore(vector.one_positions(0, 3)) catch {
    @support.SuccinctError::InvalidArgument(..) => ()
    _ => fail("expected end range error")
  }
}

///|
test "empty and uniform vectors navigate predictably" {
  let empty = from_bools([])
  assert_eq(empty.next1(0), None)
  assert_eq(empty.next0(0), None)
  assert_eq(empty.previous1(0), None)
  assert_eq(empty.previous0(0), None)
  let zeros = from_bools([false, false, false])
  assert_eq(zeros.next1(0), None)
  assert_eq(zeros.previous1(3), None)
  assert_eq(zeros.zero_positions(0, 3), [0, 1, 2])
  let ones = from_bools([true, true, true])
  assert_eq(ones.next0(0), None)
  assert_eq(ones.previous0(3), None)
  assert_eq(ones.one_positions(0, 3), [0, 1, 2])
}
