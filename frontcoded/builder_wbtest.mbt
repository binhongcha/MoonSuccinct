///|
test "dictionary parts reject trailing bytes inside the final block" {
  ignore(from_parts(1, 1, b"\x01a\x00", [0])) catch {
    @support.SuccinctError::InvalidEncoding(..) => ()
    _ => fail("expected non-canonical block rejection")
  }
}

///|
test "dictionary parts reject gaps before a later restart" {
  ignore(from_parts(2, 1, b"\x01a\x00\x01b", [0, 3])) catch {
    @support.SuccinctError::InvalidEncoding(..) => ()
    _ => fail("expected restart alignment rejection")
  }
}

///|
test "dictionary parts accept exactly consumed canonical blocks" {
  let dictionary = from_parts(2, 1, b"\x01a\x01b", [0, 2])
  assert_eq(dictionary.to_terms(), [b"a", b"b"])
}
