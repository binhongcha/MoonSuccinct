///|
fn naive_rank(bits : Array[Bool], position : Int, target : Bool) -> Int {
  let mut count = 0
  for index = 0; index < position; index = index + 1 {
    if bits[index] == target {
      count += 1
    }
  }
  count
}

///|
fn patterned_bits(length : Int, salt : Int) -> Array[Bool] {
  let result : Array[Bool] = []
  for index = 0; index < length; index = index + 1 {
    let mixed = index * 37 + salt * 19 + index / 7 * 11
    result.push(mixed % 13 < 5)
  }
  result
}

///|
test "rank matches naive scans around directory boundaries" {
  let lengths = [0, 1, 2, 63, 64, 65, 127, 128, 511, 512, 513, 1025]
  for length in lengths {
    for salt = 0; salt < 4; salt = salt + 1 {
      let bits = patterned_bits(length, salt)
      let vector = from_bools(bits)
      for position = 0; position <= length; position = position + 1 {
        assert_eq(vector.rank1(position), naive_rank(bits, position, true))
        assert_eq(vector.rank0(position), naive_rank(bits, position, false))
      }
    }
  }
}

///|
test "rank range composes prefix ranks" {
  let bits = patterned_bits(700, 9)
  let vector = from_bools(bits)
  let ranges = [(0, 0), (0, 64), (63, 65), (128, 512), (511, 700)]
  for range in ranges {
    let start = range.0
    let end = range.1
    let expected_ones = naive_rank(bits, end, true) -
      naive_rank(bits, start, true)
    assert_eq(vector.rank1_range(start, end), expected_ones)
    assert_eq(vector.rank0_range(start, end), end - start - expected_ones)
  }
}

///|
test "rank rejects positions and ranges outside the logical vector" {
  let vector = from_bools([true, false])
  ignore(vector.rank1(-1)) catch {
    @support.SuccinctError::OutOfRange(..) => ()
    _ => fail("expected rank range error")
  }
  ignore(vector.rank0(3)) catch {
    @support.SuccinctError::OutOfRange(..) => ()
    _ => fail("expected rank range error")
  }
  ignore(vector.rank1_range(2, 1)) catch {
    @support.SuccinctError::InvalidArgument(..) => ()
    _ => fail("expected invalid range")
  }
}
