///|
test "builder packs across word boundaries and owns snapshots" {
  let builder = BitBuilder::new()
  builder.push(true)
  builder.push_repeated(false, 63)
  builder.push(true)
  let first = builder.finish()
  builder.push(true)
  let second = builder.finish()
  assert_eq(first.length(), 65)
  assert_eq(first.one_count(), 2)
  assert_eq(first.zero_count(), 63)
  assert_eq(first.word_count(), 2)
  assert_eq(first.get(0), Some(true))
  assert_eq(first.get(63), Some(false))
  assert_eq(first.get(64), Some(true))
  assert_eq(first.get(65), None)
  assert_eq(second.length(), 66)
  assert_eq(second.one_count(), 3)
}

///|
test "from words enforces canonical padding" {
  let vector = from_words([5UL], 3)
  assert_eq(vector.to_bools(), [true, false, true])
  ignore(from_words([0x80UL], 3)) catch {
    @support.SuccinctError::InvalidArgument(..) => ()
    _ => fail("expected invalid padding")
  }
}

///|
test "empty and boolean constructors are defined" {
  let empty = from_bools([])
  assert_true(empty.is_empty())
  assert_eq(empty.packed_words(), [])
  let vector = from_bools([false, true, true, false])
  assert_eq(vector.length(), 4)
  assert_eq(vector.packed_words(), [6UL])
  assert_eq(vector.to_bools(), [false, true, true, false])
}
