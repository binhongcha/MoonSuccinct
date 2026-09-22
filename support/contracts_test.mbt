///|
test "stable error codes cover every public category" {
  let errors : Array[(SuccinctError, String)] = [
    (InvalidArgument(context="x", detail="bad"), "MOONSUCCINCT_ARGUMENT"),
    (InvalidSequence(index=2, detail="bad"), "MOONSUCCINCT_SEQUENCE"),
    (OutOfRange(context="x", index=3, length=2), "MOONSUCCINCT_RANGE"),
    (NumericOverflow(context="x"), "MOONSUCCINCT_OVERFLOW"),
    (TruncatedInput(offset=1, context="x"), "MOONSUCCINCT_TRUNCATED"),
    (
      InvalidEncoding(offset=1, context="x", detail="bad"),
      "MOONSUCCINCT_ENCODING",
    ),
    (
      ResourceLimit(limit="x", actual=2L, maximum=1L),
      "MOONSUCCINCT_RESOURCE_LIMIT",
    ),
    (UnsupportedVersion(format="x", version=2), "MOONSUCCINCT_VERSION"),
  ]
  for pair in errors {
    assert_eq(pair.0.code(), pair.1)
    assert_true(pair.0.message().length() > 0)
  }
}

///|
test "error classification separates malformed input and retryable limits" {
  let limit = SuccinctError::ResourceLimit(limit="items", actual=2L, maximum=1L)
  assert_true(limit.is_limit_error())
  assert_false(limit.is_malformed_input())
  assert_true(
    SuccinctError::TruncatedInput(offset=0, context="x").is_malformed_input(),
  )
  assert_true(
    SuccinctError::InvalidEncoding(offset=0, context="x", detail="bad").is_malformed_input(),
  )
  assert_true(
    SuccinctError::UnsupportedVersion(format="x", version=2).is_malformed_input(),
  )
  assert_false(
    SuccinctError::InvalidArgument(context="x", detail="bad").is_malformed_input(),
  )
}

///|
test "decode limits reject every negative budget" {
  let values : Array[(Int, Int, Int, Int)] = [
    (-1, 0, 0, 0),
    (0, -1, 0, 0),
    (0, 0, -1, 0),
    (0, 0, 0, -1),
  ]
  for value in values {
    ignore(DecodeLimits::new(value.0, value.1, value.2, value.3)) catch {
      InvalidArgument(..) => ()
      _ => fail("expected negative decode-budget rejection")
    }
  }
}

///|
test "space reports and prefix joins validate caller counts" {
  ignore(SpaceReport::new("bad", -1, 0L, 0L, 0)) catch {
    InvalidArgument(..) => ()
    _ => fail("expected negative space-report rejection")
  }
  ignore(join_prefix_suffix(b"ab", 3, b"c")) catch {
    InvalidArgument(..) => ()
    _ => fail("expected invalid prefix rejection")
  }
  let empty = SpaceReport::new("empty", 0, 0L, 0L, 0)
  assert_eq(empty.accounted_bytes(), 0L)
  assert_eq(empty.bits_per_item(), 0.0)
}
