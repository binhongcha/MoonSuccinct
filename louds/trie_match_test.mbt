///|
test "lexical select and rank invert on binary terms including the empty term" {
  let terms = [b"", b"a", b"aa", b"ab", b"b", Bytes::from_array([255])]
  let trie = @louds.trie_from_terms(terms)
  for i = 0; i < terms.length(); i = i + 1 {
    assert_eq(trie.term_at(i), Some(terms[i]))
    assert_eq(trie.term_number(trie.term_at(i).unwrap()), Some(i))
  }
  assert_eq(trie.term_at(-1), None)
  assert_eq(trie.term_at(terms.length()), None)
  assert_eq(@louds.trie_from_terms([]).term_at(0), None)
}

///|
test "stored prefix matching returns byte lengths with explicit empty semantics" {
  let trie = @louds.trie_from_terms([
    b"",
    b"a",
    b"ab",
    b"abcd",
    Bytes::from_array([255]),
  ])
  assert_eq(trie.prefix_lengths(b"abcde"), [0, 1, 2, 4])
  assert_eq(trie.longest_prefix_length(b"abcde"), Some(4))
  assert_eq(trie.longest_prefix_length(b"z"), Some(0))
  assert_eq(trie.longest_prefix_length(Bytes::from_array([255, 0])), Some(1))
  assert_eq(@louds.trie_from_terms([b"a"]).longest_prefix_length(b"z"), None)
  assert_eq(trie.prefix_lengths(b""), [0])
  ignore(trie.prefix_lengths(b"abcde", max_matches=3)) catch {
    @support.SuccinctError::InvalidArgument(..) => ()
    _ => fail("expected match budget rejection")
  }
  assert_eq(
    @louds.trie_from_terms([b"a"]).prefix_lengths(b"z", max_matches=0),
    [],
  )
}

///|
test "deep term selection and enumeration avoid the call stack" {
  let deep = Bytes::from_array(Array::make(6000, b'x'))
  let sibling = Bytes::from_array([b'x', b'y'])
  let trie = @louds.trie_from_terms([deep, sibling])
  assert_eq(trie.term_at(0), Some(deep))
  assert_eq(trie.terms_with_prefix(b"x", 2), [deep, sibling])
  assert_eq(trie.longest_prefix_length(deep), Some(6000))
}
