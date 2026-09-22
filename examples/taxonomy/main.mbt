///|
fn main raise {
  // A static route/taxonomy vocabulary; terms may be arbitrary bytes.
  let routes : Array[Bytes] = [
    b"api", b"api/admin", b"api/admin/audit", b"api/catalog", b"api/catalog/items",
    b"assets", b"assets/fonts", b"assets/images",
  ]
  let trie = @louds.trie_from_terms(routes)
  assert_true(trie.contains(b"api/admin"))
  assert_false(trie.contains(b"api/unknown"))
  assert_true(trie.find_node(b"api/") is Some(_))
  let matches = trie.terms_with_prefix(b"api/catalog", 10)
  assert_eq(matches, [b"api/catalog", b"api/catalog/items"])
  let range = trie.prefix_range(b"assets")
  assert_eq(range.end - range.start, 3)
  let restored = @louds.decode_trie(@louds.encode_trie(trie))
  assert_eq(
    restored.terms_with_prefix(b"api", 20),
    trie.terms_with_prefix(b"api", 20),
  )
  let report = trie.space_report()
  println(
    "terms=\{report.logical_items} nodes=\{trie.node_count()} serialized_bytes=\{report.serialized_bytes}",
  )
}
