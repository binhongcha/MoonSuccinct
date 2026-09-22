///|
test "Elias-Fano format round trips logical and query behavior" {
  let cases : Array[Array[UInt64]] = [
    [],
    [0UL],
    [0UL, 0UL, 0UL],
    [1UL, 2UL, 3UL, 100UL, 1000000UL],
    generated_monotone(1000, 7),
    [0xffffffffffffffffUL],
  ]
  for values in cases {
    let original = from_values(values)
    let bytes = encode(original)
    let restored = decode(bytes)
    assert_eq(restored.to_values(), values)
    assert_eq(restored.low_width(), original.low_width())
    assert_eq(encode(restored), bytes)
  }
}

///|
test "Elias-Fano decoder rejects truncation and structural corruption" {
  let bytes = encode(from_values([1UL, 4UL, 4UL, 99UL]))
  for length = 0; length < bytes.length(); length = length + 1 {
    let prefix : Array[Byte] = []
    for index = 0; index < length; index = index + 1 {
      prefix.push(bytes[index])
    }
    ignore(decode(Bytes::from_array(prefix))) catch {
      @support.SuccinctError::TruncatedInput(..) => ()
      @support.SuccinctError::InvalidArgument(..) => ()
      _ => fail("expected every strict prefix to be rejected")
    }
  }
  let invalid_flag = b"MSEF\x01\x00\x02\x00\x00\x00"
  ignore(decode(invalid_flag)) catch {
    @support.SuccinctError::InvalidEncoding(..) => ()
    _ => fail("expected invalid maximum flag")
  }
}

///|
test "Elias-Fano decoder enforces caller limits" {
  let bytes = encode(from_values(generated_monotone(20, 2)))
  let limits = @support.DecodeLimits::new(10000, 10, 100, 100)
  ignore(decode(bytes, limits~)) catch {
    @support.SuccinctError::ResourceLimit(limit~, ..) =>
      assert_eq(limit, "items")
    _ => fail("expected item limit")
  }
}
