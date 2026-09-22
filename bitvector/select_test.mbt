///|
fn naive_positions(bits : Array[Bool], target : Bool) -> Array[Int] {
  let result : Array[Int] = []
  for index = 0; index < bits.length(); index = index + 1 {
    if bits[index] == target {
      result.push(index)
    }
  }
  result
}

///|
test "select matches every naive occurrence" {
  let lengths = [0, 1, 2, 63, 64, 65, 127, 512, 513, 1031]
  for length in lengths {
    let bits = patterned_bits(length, 17)
    let vector = from_bools(bits)
    let ones = naive_positions(bits, true)
    let zeros = naive_positions(bits, false)
    for occurrence = 0; occurrence < ones.length(); occurrence = occurrence + 1 {
      assert_eq(vector.select1(occurrence), Some(ones[occurrence]))
    }
    for occurrence = 0; occurrence < zeros.length(); occurrence = occurrence + 1 {
      assert_eq(vector.select0(occurrence), Some(zeros[occurrence]))
    }
    assert_eq(vector.select1(-1), None)
    assert_eq(vector.select0(-1), None)
    assert_eq(vector.select1(ones.length()), None)
    assert_eq(vector.select0(zeros.length()), None)
  }
}

///|
test "select handles uniform runs and final partial words" {
  let zeroes = from_bools(Array::make(130, false))
  assert_eq(zeroes.select1(0), None)
  assert_eq(zeroes.select0(0), Some(0))
  assert_eq(zeroes.select0(64), Some(64))
  assert_eq(zeroes.select0(129), Some(129))
  let ones = from_bools(Array::make(130, true))
  assert_eq(ones.select0(0), None)
  assert_eq(ones.select1(129), Some(129))
}

///|
test "next and previous use inclusive and exclusive positions" {
  let vector = from_bools([false, true, false, false, true])
  assert_eq(vector.next1(0), Some(1))
  assert_eq(vector.next1(1), Some(1))
  assert_eq(vector.next1(2), Some(4))
  assert_eq(vector.next1(5), None)
  assert_eq(vector.previous1(0), None)
  assert_eq(vector.previous1(1), None)
  assert_eq(vector.previous1(2), Some(1))
  assert_eq(vector.previous1(5), Some(4))
  assert_eq(vector.next0(2), Some(2))
  assert_eq(vector.previous0(4), Some(3))
  ignore(vector.next0(6)) catch {
    @support.SuccinctError::OutOfRange(..) => ()
    _ => fail("expected next position range error")
  }
  ignore(vector.previous1(-1)) catch {
    @support.SuccinctError::OutOfRange(..) => ()
    _ => fail("expected previous one range error")
  }
  ignore(vector.previous0(6)) catch {
    @support.SuccinctError::OutOfRange(..) => ()
    _ => fail("expected previous zero range error")
  }
}
