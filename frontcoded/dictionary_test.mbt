///|
test "front-coded dictionary sorts deduplicates and owns binary terms" {
  let source = [
    b"beta",
    b"alpha",
    b"alphabet",
    b"alpha",
    Bytes::from_array([0, 255]),
  ]
  let dictionary = from_terms(source, block_size=2)
  source[0] = b"changed"
  assert_eq(dictionary.to_terms(), [
    Bytes::from_array([0, 255]),
    b"alpha",
    b"alphabet",
    b"beta",
  ])
  assert_eq(dictionary.length(), 4)
  assert_eq(dictionary.block_size(), 2)
  assert_eq(dictionary.block_count(), 2)
  assert_true(dictionary.encoded_bytes() > 0)
}

///|
fn numbered_term(index : Int) -> Bytes {
  let bytes : Array[Byte] = []
  for byte in b"shared-prefix-" {
    bytes.push(byte)
  }
  bytes.push((index / 10).to_byte())
  bytes.push((index % 10).to_byte())
  Bytes::from_array(bytes)
}

///|
test "front-coded dictionary random access spans restart blocks" {
  let terms : Array[Bytes] = []
  for index = 0; index < 35; index = index + 1 {
    terms.push(numbered_term(index))
  }
  let dictionary = from_terms(terms, block_size=8)
  assert_eq(dictionary.to_terms(), terms)
  assert_eq(dictionary.get(-1), None)
  assert_eq(dictionary.get(35), None)
}

///|
test "front-coded lookup and prefix queries are lexicographic" {
  let dictionary = from_terms(
    [b"team", b"tea", b"ten", b"to", b"ted", b"a"],
    block_size=3,
  )
  assert_eq(dictionary.term_number(b"a"), Some(0))
  assert_eq(dictionary.term_number(b"tea"), Some(1))
  assert_eq(dictionary.term_number(b"missing"), None)
  assert_true(dictionary.contains(b"to"))
  assert_false(dictionary.contains(b"te"))
  assert_eq(dictionary.prefix_range(b"te"), { start: 1, end: 5, })
  assert_eq(dictionary.terms_with_prefix(b"te", 3), [b"tea", b"team", b"ted"])
}

///|
test "front-coded dictionary validates configuration and range" {
  ignore(from_terms([], block_size=0)) catch {
    @support.SuccinctError::InvalidArgument(..) => ()
    _ => fail("expected invalid block size")
  }
  let dictionary = from_terms([b"a"])
  ignore(dictionary.at(1)) catch {
    @support.SuccinctError::OutOfRange(..) => ()
    _ => fail("expected term range error")
  }
  ignore(dictionary.terms_with_prefix(b"", -1)) catch {
    @support.SuccinctError::InvalidArgument(..) => ()
    _ => fail("expected enumeration limit error")
  }
}
