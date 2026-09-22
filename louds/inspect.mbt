///|
/// Representation statistics for a LOUDS trie.
pub(all) struct TrieStatistics {
  nodes : Int
  edges : Int
  terms : Int
  topology_bits : Int
  label_bytes : Int
  terminal_bits : Int
  subtree_counter_bytes : Int
} derive(Debug, Eq)

///|
/// Inspect each conceptual representation component.
pub fn Trie::statistics(self : Trie) -> TrieStatistics {
  {
    nodes: self.topology.node_count(),
    edges: self.topology.edge_count(),
    terms: self.terms,
    topology_bits: self.topology.bit_length(),
    label_bytes: self.edge_labels.length(),
    terminal_bits: self.terminals.length(),
    subtree_counter_bytes: self.subtree_terms.length() * 4,
  }
}

///|
/// Portable space accounting. Payload contains packed topology/terminal words
/// and edge labels; auxiliary bits include their rank directories and cached
/// subtree term counts.
pub fn Trie::space_report(
  self : Trie,
) -> @support.SpaceReport raise @support.SuccinctError {
  let topology_report = self.topology.bits.space_report()
  let terminal_report = self.terminals.space_report()
  let payload = topology_report.payload_bits +
    terminal_report.payload_bits +
    self.edge_labels.length().to_int64() * 8L
  let auxiliary = topology_report.auxiliary_bits +
    terminal_report.auxiliary_bits +
    self.subtree_terms.length().to_int64() * 32L
  @support.SpaceReport::new(
    "louds-trie",
    self.terms,
    payload,
    auxiliary,
    encode_trie(self).length(),
  )
}
