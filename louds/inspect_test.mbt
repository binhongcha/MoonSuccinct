///|
test "trie reports topology labels terminals and cached counts" {
  let trie = trie_from_terms([b"", b"alpha", b"alpine", b"beta"])
  let stats = trie.statistics()
  assert_eq(stats.terms, 4)
  assert_eq(stats.edges, stats.nodes - 1)
  assert_eq(stats.label_bytes, stats.edges)
  assert_eq(stats.terminal_bits, stats.nodes)
  assert_eq(stats.subtree_counter_bytes, stats.nodes * 4)
  let report = trie.space_report()
  assert_eq(report.structure, "louds-trie")
  assert_eq(report.logical_items, 4)
  assert_true(report.payload_bits > 0L)
  assert_true(report.auxiliary_bits > 0L)
  assert_eq(report.serialized_bytes, encode_trie(trie).length())
}
