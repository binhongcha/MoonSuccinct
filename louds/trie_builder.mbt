///|
fn find_child_slot(node : MutableNode, label : Byte) -> (Int, Bool) {
  let mut low = 0
  let mut high = node.labels.length()
  while low < high {
    let middle = low + (high - low) / 2
    if node.labels[middle].to_int() < label.to_int() {
      low = middle + 1
    } else {
      high = middle
    }
  }
  (low, low < node.labels.length() && node.labels[low] == label)
}

///|
fn insert_child(
  node : MutableNode,
  slot : Int,
  label : Byte,
  child : Int,
) -> Unit {
  node.labels.push(label)
  node.children.push(child)
  let mut cursor = node.labels.length() - 1
  while cursor > slot {
    node.labels[cursor] = node.labels[cursor - 1]
    node.children[cursor] = node.children[cursor - 1]
    cursor -= 1
  }
  node.labels[slot] = label
  node.children[slot] = child
}

///|
/// Build a static trie from arbitrary byte terms. Terms are deduplicated and
/// child order is canonical unsigned-byte lexicographic order.
pub fn trie_from_terms(
  terms : Array[Bytes],
) -> Trie raise @support.SuccinctError {
  let nodes : Array[MutableNode] = [
    { terminal: false, labels: [], children: [], },
  ]
  let mut term_count = 0
  for term in terms {
    let mut node_id = 0
    for label in term {
      let node = nodes[node_id]
      let (slot, exists) = find_child_slot(node, label)
      if exists {
        node_id = node.children[slot]
      } else {
        let child_id = nodes.length()
        nodes.push({ terminal: false, labels: [], children: [], })
        insert_child(node, slot, label, child_id)
        node_id = child_id
      }
    }
    if !nodes[node_id].terminal {
      nodes[node_id].terminal = true
      term_count += 1
    }
  }
  let queue : Array[Int] = [0]
  let degrees : Array[Int] = []
  let labels : Array[Byte] = []
  let terminal_builder = @bitvector.BitBuilder::new()
  let mut cursor = 0
  while cursor < queue.length() {
    let node = nodes[queue[cursor]]
    degrees.push(node.children.length())
    terminal_builder.push(node.terminal)
    for index = 0; index < node.children.length(); index = index + 1 {
      labels.push(node.labels[index])
      queue.push(node.children[index])
    }
    cursor += 1
  }
  let topology = from_degrees(degrees)
  let terminals = terminal_builder.finish()
  let subtree_terms = Array::make(topology.node_count(), 0)
  for node = topology.node_count() - 1; node >= 0; node = node - 1 {
    let mut count = if terminals.get(node).unwrap() { 1 } else { 0 }
    for child in topology.children_valid(node) {
      count += subtree_terms[child]
    }
    subtree_terms[node] = count
  }
  {
    topology,
    edge_labels: Bytes::from_array(labels),
    terminals,
    subtree_terms,
    terms: term_count,
  }
}
