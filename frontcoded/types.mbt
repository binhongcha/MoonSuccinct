///|
/// Immutable block front-coded dictionary over distinct sorted byte terms.
pub struct Dictionary {
  terms : Int
  block_size : Int
  encoded : Bytes
  block_offsets : Array[Int]
}

///|
/// Half-open lexicographic term-number range.
pub(all) struct TermRange {
  start : Int
  end : Int
} derive(Debug, Eq)

///|
fn copy_terms(input : Array[Bytes]) -> Array[Bytes] {
  let copied : Array[Bytes] = []
  for term in input {
    copied.push(@support.copy_bytes(term))
  }
  copied
}

///|
fn sort_terms(terms : Array[Bytes]) -> Unit {
  terms.sort_by((left, right) => @support.compare_bytes(left, right))
}

///|
fn deduplicate_sorted(terms : Array[Bytes]) -> Array[Bytes] {
  let distinct : Array[Bytes] = []
  for term in terms {
    if distinct.length() == 0 ||
      @support.compare_bytes(distinct[distinct.length() - 1], term) != 0 {
      distinct.push(term)
    }
  }
  distinct
}
