///|
fn test_width_mask(width : Int) -> UInt64 {
  if width == 0 {
    0UL
  } else if width == 64 {
    0xffffffffffffffffUL
  } else {
    (1UL << width) - 1UL
  }
}

///|
test "packed integers round trip widths and cross-word boundaries" {
  let widths = [0, 1, 2, 7, 13, 31, 32, 33, 63, 64]
  for width in widths {
    let values : Array[UInt64] = []
    let mask = test_width_mask(width)
    for index = 0; index < 137; index = index + 1 {
      let raw = index.to_uint64() * 0x9e3779b97f4a7c15UL + 0x517cc1b727220a95UL
      values.push(raw & mask)
    }
    let packed = from_values(values, width)
    assert_eq(packed.width(), width)
    assert_eq(packed.length(), values.length())
    assert_eq(packed.to_values(), values)
    assert_eq(
      from_words(packed.packed_words(), packed.length(), width).to_values(),
      values,
    )
  }
}

///|
test "packed integers reject width overflow and padding data" {
  ignore(from_values([4UL], 2)) catch {
    @support.SuccinctError::InvalidSequence(..) => ()
    _ => fail("expected width overflow")
  }
  ignore(from_values([], 65)) catch {
    @support.SuccinctError::InvalidArgument(..) => ()
    _ => fail("expected invalid width")
  }
  ignore(from_words([0xffffffffffffffffUL], 1, 1)) catch {
    @support.SuccinctError::InvalidArgument(..) => ()
    _ => fail("expected non-zero padding")
  }
}

///|
test "packed integer snapshots own their input words" {
  let input = [1UL]
  let packed = from_words(input, 1, 1)
  input[0] = 0UL
  assert_eq(packed.at(0), 1UL)
  let output = packed.packed_words()
  output[0] = 0UL
  assert_eq(packed.at(0), 1UL)
}

///|
test "packed integer metadata and ranges are checked" {
  let packed = from_values([1UL, 2UL, 3UL], 2)
  assert_eq(packed.word_count(), 1)
  assert_eq(packed.get(-1), None)
  assert_eq(packed.get(3), None)
  ignore(packed.at(3)) catch {
    @support.SuccinctError::OutOfRange(..) => ()
    _ => fail("expected packed integer range error")
  }
  ignore(from_words([], -1, 1)) catch {
    @support.SuccinctError::InvalidArgument(..) => ()
    _ => fail("expected negative packed length rejection")
  }
  ignore(from_words([], 1, 1)) catch {
    @support.SuccinctError::InvalidArgument(..) => ()
    _ => fail("expected packed word count rejection")
  }
  ignore(from_words([], 40000000, 64)) catch {
    @support.SuccinctError::ResourceLimit(limit~, ..) =>
      assert_eq(limit, "packed_bits")
    _ => fail("expected packed bit resource limit")
  }
}
