///|
test "fixed integers and bytes round trip" {
  let writer = Writer::new()
  writer.write_byte(0xab)
  writer.write_u32(0x78563412U)
  writer.write_u64(0x8877665544332211UL)
  writer.write_length_prefixed(b"moon")
  let encoded = writer.finish()
  let reader = Reader::new(encoded)
  assert_eq(reader.read_byte(), 0xab)
  assert_eq(reader.read_u32(), 0x78563412U)
  assert_eq(reader.read_u64(), 0x8877665544332211UL)
  assert_eq(reader.read_term("name"), b"moon")
  reader.finish("fixture")
}

///|
test "varints are canonical for representative boundaries" {
  let values : Array[UInt64] = [
    0UL, 1UL, 127UL, 128UL, 16383UL, 16384UL, 0xffffffffUL, 0xffffffffffffffffUL,
  ]
  for value in values {
    let writer = Writer::new()
    writer.write_varint(value)
    let encoded = writer.finish()
    assert_eq(encoded.length(), varint_length(value))
    let reader = Reader::new(encoded)
    assert_eq(reader.read_varint(), value)
    reader.finish("varint")
  }
}

///|
test "reader rejects truncation overlong values and trailing bytes" {
  let truncated = Reader::new(b"\x01\x02")
  ignore(truncated.read_u32()) catch {
    @support.SuccinctError::TruncatedInput(..) => ()
    _ => fail("expected truncation")
  }
  let overlong = Reader::new(b"\x80\x00")
  ignore(overlong.read_varint()) catch {
    @support.SuccinctError::InvalidEncoding(..) => ()
    _ => fail("expected non-canonical encoding")
  }
  let trailing = Reader::new(b"\x00")
  ignore(trailing.finish("test")) catch {
    @support.SuccinctError::InvalidEncoding(..) => ()
    _ => fail("expected trailing byte rejection")
  }
}

///|
test "reader enforces cumulative term bytes without consuming rejected data" {
  let limits = @support.DecodeLimits::new(100, 100, 10, 5)
  let reader = Reader::new(b"\x03abc\x03def", limits~)
  assert_eq(reader.read_term("first"), b"abc")
  ignore(reader.read_term("second")) catch {
    @support.SuccinctError::ResourceLimit(limit~, actual~, maximum~) => {
      assert_eq(limit, "total_term_bytes")
      assert_eq(actual, 6L)
      assert_eq(maximum, 5L)
    }
    _ => fail("expected cumulative term-byte limit")
  }
  assert_eq(reader.position(), 5)
}

///|
test "reader rejects negative raw lengths and overflowing unsigned varints" {
  let reader = Reader::new(b"")
  ignore(reader.read_bytes(-1)) catch {
    @support.SuccinctError::InvalidArgument(..) => ()
    _ => fail("expected negative read count rejection")
  }
  let overflow = Reader::new(b"\xff\xff\xff\xff\xff\xff\xff\xff\xff\x02")
  ignore(overflow.read_varint()) catch {
    @support.SuccinctError::NumericOverflow(..) => ()
    _ => fail("expected UInt64 varint overflow")
  }
}

///|
test "count and term lengths must fit the MoonBit Int domain" {
  let encoded = b"\x80\x80\x80\x80\x08"
  let count = Reader::new(encoded)
  ignore(count.read_count("count")) catch {
    @support.SuccinctError::NumericOverflow(..) => ()
    _ => fail("expected count overflow")
  }
  let term = Reader::new(encoded)
  ignore(term.read_term("term")) catch {
    @support.SuccinctError::NumericOverflow(..) => ()
    _ => fail("expected term length overflow")
  }
}
