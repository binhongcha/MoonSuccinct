///|
fn main raise {
  // Byte prefixes include explicit separators supplied by the application.
  let trie = @louds.trie_from_terms([b"/", b"/api/", b"/api/v2/", b"/assets/"])
  assert_eq(trie.prefix_lengths(b"/api/v2/items"), [1, 5, 8])
  assert_eq(trie.longest_prefix_length(b"/api/v2/items"), Some(8))
  for rank = 0; rank < trie.term_count(); rank = rank + 1 {
    let term = trie.term_at(rank).unwrap()
    assert_eq(trie.term_number(term), Some(rank))
  }
  println("Lexical term selection and hierarchical byte-prefix matching: ok")
}
