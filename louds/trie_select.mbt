///|
/// Recover the term at a zero-based lexical rank by skipping whole subtrees.
/// Invalid ranks return None. This does not enumerate preceding terms.
pub fn Trie::term_at(self : Trie, index : Int) -> Bytes? {
  if index < 0 || index >= self.terms {
    return None
  }
  let path : Array[Byte] = []
  let mut remaining = index
  let mut node = 0
  while true {
    if self.terminals.get(node).unwrap() {
      if remaining == 0 {
        return Some(Bytes::from_array(path))
      }
      remaining -= 1
    }
    let mut found = false
    for child in self.topology.children_valid(node) {
      if remaining >= self.subtree_terms[child] {
        remaining -= self.subtree_terms[child]
      } else {
        path.push(self.edge_labels[child - 1])
        node = child
        found = true
        break
      }
    }
    if !found {
      return None
    }
  }
  None
}
