///|
priv struct MutableNode {
  mut terminal : Bool
  labels : Array[Byte]
  children : Array[Int]
}

///|
/// Immutable byte trie backed by a LOUDS topology.
pub struct Trie {
  topology : Topology
  edge_labels : Bytes
  terminals : @bitvector.BitVector
  subtree_terms : Array[Int]
  terms : Int
}

///|
/// Half-open lexicographic range of term numbers.
pub(all) struct TermRange {
  start : Int
  end : Int
} derive(Debug, Eq)
