///|
fn bitvector_fixture(
  version : Int,
  length : UInt64,
  words : Array[UInt64],
) -> Bytes {
  let writer = @binary.Writer::new()
  writer.write_bytes(b"MSBV")
  writer.write_byte(version.to_byte())
  writer.write_varint(length)
  writer.write_varint(words.length().to_uint64())
  for word in words {
    writer.write_u64(word)
  }
  writer.finish()
}

///|
test "bit vector decoder rejects truncated structural regions" {
  let valid = encode(from_bools([true, false, true]))
  for length = 0; length < valid.length(); length = length + 1 {
    let truncated : Array[Byte] = []
    for index = 0; index < length; index = index + 1 {
      truncated.push(valid[index])
    }
    ignore(decode(Bytes::from_array(truncated))) catch {
      @support.SuccinctError::TruncatedInput(..) => ()
      _ => fail("expected truncation for every strict prefix")
    }
  }
}

///|
test "bit vector decoder rejects format and count inconsistencies" {
  ignore(decode(b"NOPE\x01\x00\x00")) catch {
    @support.SuccinctError::InvalidEncoding(..) => ()
    _ => fail("expected bad magic")
  }
  ignore(decode(bitvector_fixture(2, 0UL, []))) catch {
    @support.SuccinctError::UnsupportedVersion(..) => ()
    _ => fail("expected unsupported version")
  }
  ignore(decode(bitvector_fixture(1, 65UL, [0UL]))) catch {
    @support.SuccinctError::InvalidEncoding(..) => ()
    _ => fail("expected word-count mismatch")
  }
  ignore(decode(bitvector_fixture(1, 3UL, [0x80UL]))) catch {
    @support.SuccinctError::InvalidArgument(..) => ()
    _ => fail("expected non-zero padding rejection")
  }
}

///|
test "bit vector decoder rejects trailing bytes and resource excess" {
  let encoded = encode(from_bools([true, false, true]))
  let with_trailing : Array[Byte] = []
  for byte in encoded {
    with_trailing.push(byte)
  }
  with_trailing.push(0)
  ignore(decode(Bytes::from_array(with_trailing))) catch {
    @support.SuccinctError::InvalidEncoding(..) => ()
    _ => fail("expected trailing byte rejection")
  }
  let tiny_input = @support.DecodeLimits::new(4, 100, 100, 100)
  ignore(decode(encoded, limits=tiny_input)) catch {
    @support.SuccinctError::ResourceLimit(limit~, ..) =>
      assert_eq(limit, "input_bytes")
    _ => fail("expected input limit")
  }
  let tiny_items = @support.DecodeLimits::new(100, 2, 100, 100)
  ignore(decode(encoded, limits=tiny_items)) catch {
    @support.SuccinctError::ResourceLimit(limit~, ..) =>
      assert_eq(limit, "items")
    _ => fail("expected item limit")
  }
}
