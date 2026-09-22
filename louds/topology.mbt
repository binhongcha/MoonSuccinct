///|
/// Immutable level-order unary degree sequence for one rooted ordered tree.
pub struct Topology {
  bits : @bitvector.BitVector
  nodes : Int
}

///|
/// Build a LOUDS topology from node degrees in breadth-first order.
pub fn from_degrees(
  degrees : Array[Int],
) -> Topology raise @support.SuccinctError {
  if degrees.length() == 0 {
    raise @support.SuccinctError::InvalidArgument(
      context="LOUDS degrees",
      detail="a rooted tree requires at least one node",
    )
  }
  let builder = @bitvector.BitBuilder::new()
  let mut open_slots = 1
  let mut edges = 0
  let maximum_edges = degrees.length() - 1
  for index = 0; index < degrees.length(); index = index + 1 {
    let degree = degrees[index]
    if degree < 0 {
      raise @support.SuccinctError::InvalidSequence(
        index~,
        detail="node degree must be non-negative",
      )
    }
    if open_slots == 0 {
      raise @support.SuccinctError::InvalidSequence(
        index~,
        detail="node is unreachable from the root",
      )
    }
    if degree > maximum_edges - edges {
      raise @support.SuccinctError::InvalidSequence(
        index~,
        detail="degree sum exceeds the edge count of one rooted tree",
      )
    }
    open_slots = open_slots - 1 + degree
    edges += degree
    builder.push_repeated(true, degree)
    builder.push(false)
  }
  if open_slots != 0 || edges != degrees.length() - 1 {
    raise @support.SuccinctError::InvalidSequence(
      index=degrees.length() - 1,
      detail="degree sequence does not close exactly one rooted tree",
    )
  }
  { bits: builder.finish(), nodes: degrees.length(), }
}

///|
/// Rebuild from a validated canonical LOUDS bit vector.
pub fn from_bitvector(
  bits : @bitvector.BitVector,
) -> Topology raise @support.SuccinctError {
  let nodes = bits.zero_count()
  if nodes == 0 || bits.one_count() != nodes - 1 {
    raise @support.SuccinctError::InvalidArgument(
      context="LOUDS bits",
      detail="expected n zero terminators and n-1 child markers",
    )
  }
  let degrees : Array[Int] = []
  let mut previous_zero = -1
  for node = 0; node < nodes; node = node + 1 {
    let zero = bits.select0(node).unwrap()
    degrees.push(zero - previous_zero - 1)
    previous_zero = zero
  }
  let rebuilt = from_degrees(degrees)
  if rebuilt.bits.to_bools() != bits.to_bools() {
    raise @support.SuccinctError::InvalidArgument(
      context="LOUDS bits",
      detail="bit sequence is not canonical",
    )
  }
  { bits, nodes, }
}

///|
/// Number of nodes.
pub fn Topology::node_count(self : Topology) -> Int {
  self.nodes
}

///|
/// Number of edges.
pub fn Topology::edge_count(self : Topology) -> Int {
  self.nodes - 1
}

///|
/// Canonical LOUDS bit length.
pub fn Topology::bit_length(self : Topology) -> Int {
  self.bits.length()
}

///|
/// Return an owned canonical LOUDS packed representation.
pub fn Topology::packed_words(self : Topology) -> Array[UInt64] {
  self.bits.packed_words()
}

///|
/// Whether a breadth-first node number is valid.
pub fn Topology::contains_node(self : Topology, node : Int) -> Bool {
  node >= 0 && node < self.nodes
}

///|
fn Topology::check_node(
  self : Topology,
  node : Int,
) -> Unit raise @support.SuccinctError {
  if !self.contains_node(node) {
    raise @support.SuccinctError::OutOfRange(
      context="LOUDS node",
      index=node,
      length=self.nodes,
    )
  }
}

///|
fn Topology::segment_start(self : Topology, node : Int) -> Int {
  if node == 0 {
    0
  } else {
    self.bits.select0(node - 1).unwrap() + 1
  }
}

///|
fn Topology::degree_valid(self : Topology, node : Int) -> Int {
  self.bits.select0(node).unwrap() - self.segment_start(node)
}

///|
/// Number of ordered children.
pub fn Topology::degree(
  self : Topology,
  node : Int,
) -> Int raise @support.SuccinctError {
  self.check_node(node)
  self.degree_valid(node)
}

///|
/// Parent node number, absent only for the root.
pub fn Topology::parent(
  self : Topology,
  node : Int,
) -> Int? raise @support.SuccinctError {
  self.check_node(node)
  if node == 0 {
    None
  } else {
    let edge_position = self.bits.select1(node - 1).unwrap()
    Some(self.bits.rank0(edge_position))
  }
}

///|
/// First child node number, absent for a leaf.
pub fn Topology::first_child(
  self : Topology,
  node : Int,
) -> Int? raise @support.SuccinctError {
  self.check_node(node)
  let start = self.segment_start(node)
  let zero = self.bits.select0(node).unwrap()
  if start == zero {
    None
  } else {
    Some(self.bits.rank1(start) + 1)
  }
}

///|
/// Child at a zero-based sibling offset.
pub fn Topology::child(
  self : Topology,
  node : Int,
  offset : Int,
) -> Int? raise @support.SuccinctError {
  if offset < 0 {
    return None
  }
  match self.first_child(node) {
    None => None
    Some(first) =>
      if offset >= self.degree(node) {
        None
      } else {
        Some(first + offset)
      }
  }
}

///|
fn Topology::children_valid(self : Topology, node : Int) -> Array[Int] {
  let count = self.degree_valid(node)
  let result : Array[Int] = []
  if count > 0 {
    let first = self.segment_start(node) - node + 1
    for offset = 0; offset < count; offset = offset + 1 {
      result.push(first + offset)
    }
  }
  result
}

///|
/// Ordered child node numbers.
pub fn Topology::children(
  self : Topology,
  node : Int,
) -> Array[Int] raise @support.SuccinctError {
  self.check_node(node)
  self.children_valid(node)
}

///|
/// Whether the node has no children.
pub fn Topology::is_leaf(
  self : Topology,
  node : Int,
) -> Bool raise @support.SuccinctError {
  self.degree(node) == 0
}

///|
/// Breadth-first degree sequence.
pub fn Topology::to_degrees(self : Topology) -> Array[Int] {
  let result : Array[Int] = []
  for node = 0; node < self.nodes; node = node + 1 {
    result.push(self.degree_valid(node))
  }
  result
}
