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
  for index = 1; index < terms.length(); index = index + 1 {
    let value = terms[index]
    let mut cursor = index
    while cursor > 0 && @support.compare_bytes(terms[cursor - 1], value) > 0 {
      terms[cursor] = terms[cursor - 1]
      cursor -= 1
    }
    terms[cursor] = value
  }
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
