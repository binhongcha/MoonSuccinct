///|
test "LOUDS trie deduplicates and serves binary exact lookups" {
  let trie = trie_from_terms([
    b"tea",
    b"to",
    b"ten",
    b"tea",
    b"",
    Bytes::from_array([0, 255]),
  ])
  assert_eq(trie.term_count(), 5)
  assert_true(trie.contains(b""))
  assert_true(trie.contains(b"tea"))
  assert_true(trie.contains(b"ten"))
  assert_true(trie.contains(b"to"))
  assert_true(trie.contains(Bytes::from_array([0, 255])))
  assert_false(trie.contains(b"te"))
  assert_false(trie.contains(b"toast"))
  assert_true(trie.find_node(b"te") is Some(_))
}

///|
test "LOUDS trie returns lexicographic term numbers and prefix ranges" {
  let trie = trie_from_terms([b"b", b"aa", b"a", b"ab", b"", b"ba"])
  assert_eq(trie.term_number(b""), Some(0))
  assert_eq(trie.term_number(b"a"), Some(1))
  assert_eq(trie.term_number(b"aa"), Some(2))
  assert_eq(trie.term_number(b"ab"), Some(3))
  assert_eq(trie.term_number(b"b"), Some(4))
  assert_eq(trie.term_number(b"ba"), Some(5))
  assert_eq(trie.prefix_range(b"a"), { start: 1, end: 4, })
  assert_eq(trie.prefix_range(b"b"), { start: 4, end: 6, })
  assert_eq(trie.prefix_range(b"z"), { start: 6, end: 6, })
}

///|
test "LOUDS trie prefix enumeration is ordered and bounded" {
  let trie = trie_from_terms([b"team", b"tea", b"ten", b"to", b"ted", b"a"])
  assert_eq(trie.terms_with_prefix(b"te", 10), [b"tea", b"team", b"ted", b"ten"])
  assert_eq(trie.terms_with_prefix(b"te", 2), [b"tea", b"team"])
  assert_eq(trie.terms_with_prefix(b"missing", 10), [])
  assert_eq(trie.terms_with_prefix(b"", 0), [])
}
