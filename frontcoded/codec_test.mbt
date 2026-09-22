///|
test "front-coded dictionary format preserves terms and queries" {
  let dictionary = from_terms(
    [b"", b"alpha", b"alphabet", b"alpine", b"beta", Bytes::from_array([255])],
    block_size=2,
  )
  let bytes = encode(dictionary)
  let restored = decode(bytes)
  assert_eq(restored.to_terms(), dictionary.to_terms())
  assert_eq(restored.block_size(), 2)
  assert_eq(restored.prefix_range(b"al"), dictionary.prefix_range(b"al"))
  assert_eq(encode(restored), bytes)
}

///|
test "front-coded decoder rejects every strict prefix" {
  let bytes = encode(from_terms([b"a", b"aa", b"b"], block_size=2))
  for length = 0; length < bytes.length(); length = length + 1 {
    let prefix : Array[Byte] = []
    for index = 0; index < length; index = index + 1 {
      prefix.push(bytes[index])
    }
    ignore(decode(Bytes::from_array(prefix))) catch {
      @support.SuccinctError::TruncatedInput(..) => ()
      @support.SuccinctError::InvalidArgument(..) => ()
      @support.SuccinctError::InvalidSequence(..) => ()
      _ => fail("expected truncated dictionary rejection")
    }
  }
}

///|
test "front-coded decoder enforces term-count limits" {
  let bytes = encode(from_terms([b"a", b"b", b"c"]))
  let limits = @support.DecodeLimits::new(1000, 2, 100, 100)
  ignore(decode(bytes, limits~)) catch {
    @support.SuccinctError::ResourceLimit(limit~, ..) =>
      assert_eq(limit, "items")
    _ => fail("expected item limit")
  }
}

///|
test "front-coded decoder enforces reconstructed and cumulative term limits" {
  let dictionary = from_terms([b"aaaa", b"aaab", b"aaac"], block_size=2)
  let bytes = encode(dictionary)
  let cumulative = @support.DecodeLimits::new(1000, 100, 10, 11)
  ignore(decode(bytes, limits=cumulative)) catch {
    @support.SuccinctError::ResourceLimit(limit~, actual~, maximum~) => {
      assert_eq(limit, "total_term_bytes")
      assert_eq(actual, 12L)
      assert_eq(maximum, 11L)
    }
    _ => fail("expected cross-block cumulative term limit")
  }
  let reconstructed = @support.DecodeLimits::new(1000, 100, 3, 100)
  ignore(decode(bytes, limits=reconstructed)) catch {
    @support.SuccinctError::ResourceLimit(limit~, actual~, maximum~) => {
      assert_eq(limit, "term_bytes")
      assert_eq(actual, 4L)
      assert_eq(maximum, 3L)
    }
    _ => fail("expected reconstructed term limit")
  }
}
