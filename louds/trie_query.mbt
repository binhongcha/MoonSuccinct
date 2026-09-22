///|
/// Number of distinct terms.
pub fn Trie::term_count(self : Trie) -> Int {
  self.terms
}

///|
/// Number of topology nodes including the root.
pub fn Trie::node_count(self : Trie) -> Int {
  self.topology.node_count()
}

///|
/// Whether node marks a complete term.
pub fn Trie::is_terminal(
  self : Trie,
  node : Int,
) -> Bool raise @support.SuccinctError {
  self.topology.check_node(node)
  self.terminals.get(node).unwrap()
}

///|
fn Trie::find_child(self : Trie, node : Int, label : Byte) -> Int? {
  let children = self.topology.children_valid(node)
  let mut low = 0
  let mut high = children.length()
  while low < high {
    let middle = low + (high - low) / 2
    let child = children[middle]
    let actual = self.edge_labels[child - 1]
    if actual.to_int() < label.to_int() {
      low = middle + 1
    } else {
      high = middle
    }
  }
  if low < children.length() && self.edge_labels[children[low] - 1] == label {
    Some(children[low])
  } else {
    None
  }
}

///|
/// Node reached by the complete byte key, even when it is only a prefix.
pub fn Trie::find_node(self : Trie, key : Bytes) -> Int? {
  let mut node = 0
  for label in key {
    match self.find_child(node, label) {
      None => return None
      Some(child) => node = child
    }
  }
  Some(node)
}

///|
/// Exact term membership.
pub fn Trie::contains(self : Trie, term : Bytes) -> Bool {
  match self.find_node(term) {
    None => false
    Some(node) => self.terminals.get(node).unwrap()
  }
}

///|
fn Trie::lexicographic_start(self : Trie, key : Bytes) -> (Int, Int?) {
  let mut node = 0
  let mut start = 0
  for label in key {
    if self.terminals.get(node).unwrap() {
      start += 1
    }
    let children = self.topology.children_valid(node)
    let mut matched : Int? = None
    for child in children {
      let actual = self.edge_labels[child - 1]
      if actual.to_int() < label.to_int() {
        start += self.subtree_terms[child]
      } else if actual == label {
        matched = Some(child)
        break
      } else {
        break
      }
    }
    match matched {
      None => return (start, None)
      Some(child) => node = child
    }
  }
  (start, Some(node))
}

///|
/// Exact zero-based lexicographic term number.
pub fn Trie::term_number(self : Trie, term : Bytes) -> Int? {
  let (start, node) = self.lexicographic_start(term)
  match node {
    Some(value) =>
      if self.terminals.get(value).unwrap() {
        Some(start)
      } else {
        None
      }
    None => None
  }
}

///|
/// Half-open lexicographic range of terms beginning with prefix.
pub fn Trie::prefix_range(self : Trie, prefix : Bytes) -> TermRange {
  let (start, node) = self.lexicographic_start(prefix)
  match node {
    None => { start, end: start, }
    Some(value) => { start, end: start + self.subtree_terms[value], }
  }
}

///|
fn Trie::collect(
  self : Trie,
  node : Int,
  path : Array[Byte],
  limit : Int,
  output : Array[Bytes],
) -> Unit {
  if output.length() >= limit {
    return
  }
  if self.terminals.get(node).unwrap() {
    output.push(Bytes::from_array(path.copy()))
  }
  for child in self.topology.children_valid(node) {
    if output.length() >= limit {
      return
    }
    self.collect(
      child,
      copy_path_with(path, self.edge_labels[child - 1]),
      limit,
      output,
    )
  }
}

///|
/// Enumerate up to limit matching terms in unsigned-byte lexicographic order.
pub fn Trie::terms_with_prefix(
  self : Trie,
  prefix : Bytes,
  limit : Int,
) -> Array[Bytes] raise @support.SuccinctError {
  if limit < 0 {
    raise @support.SuccinctError::InvalidArgument(
      context="prefix enumeration limit",
      detail="must be non-negative",
    )
  }
  if limit == 0 {
    return []
  }
  match self.find_node(prefix) {
    None => []
    Some(node) => {
      let path : Array[Byte] = []
      for byte in prefix {
        path.push(byte)
      }
      let output : Array[Bytes] = []
      self.collect(node, path, limit, output)
      output
    }
  }
}
