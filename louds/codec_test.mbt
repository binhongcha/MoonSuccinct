///|
test "LOUDS trie format preserves all queries" {
  let trie = trie_from_terms([
    b"",
    b"a",
    b"alpha",
    b"alpine",
    b"beta",
    Bytes::from_array([0, 1, 255]),
  ])
  let bytes = encode_trie(trie)
  let restored = decode_trie(bytes)
  assert_eq(restored.term_count(), trie.term_count())
  assert_eq(restored.node_count(), trie.node_count())
  assert_eq(
    restored.terms_with_prefix(b"", 20),
    trie.terms_with_prefix(b"", 20),
  )
  assert_eq(restored.prefix_range(b"al"), trie.prefix_range(b"al"))
  assert_eq(encode_trie(restored), bytes)
}

///|
test "LOUDS trie decoder rejects every strict prefix" {
  let bytes = encode_trie(trie_from_terms([b"a", b"ab", b"b"]))
  for length = 0; length < bytes.length(); length = length + 1 {
    let prefix : Array[Byte] = []
    for index = 0; index < length; index = index + 1 {
      prefix.push(bytes[index])
    }
    ignore(decode_trie(Bytes::from_array(prefix))) catch {
      @support.SuccinctError::TruncatedInput(..) => ()
      @support.SuccinctError::InvalidArgument(..) => ()
      _ => fail("expected truncated trie rejection")
    }
  }
}

///|
test "LOUDS trie decoder enforces input and term limits" {
  let bytes = encode_trie(trie_from_terms([b"alpha", b"beta"]))
  let input_limits = @support.DecodeLimits::new(4, 100, 100, 100)
  ignore(decode_trie(bytes, limits=input_limits)) catch {
    @support.SuccinctError::ResourceLimit(limit~, ..) =>
      assert_eq(limit, "input_bytes")
    _ => fail("expected input limit")
  }
  let term_limits = @support.DecodeLimits::new(1000, 100, 4, 100)
  ignore(decode_trie(bytes, limits=term_limits)) catch {
    @support.SuccinctError::ResourceLimit(limit~, ..) =>
      assert_eq(limit, "term_bytes")
    _ => fail("expected term limit")
  }
}
