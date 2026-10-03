///|
/// Byte length of the longest stored term that prefixes the input.
/// Some(0) is an empty stored term; None means no match at all.
pub fn Trie::longest_prefix_length(self : Trie, key : Bytes) -> Int? {
  let mut best = if self.terminals.get(0).unwrap() { Some(0) } else { None }
  let mut node = 0
  let mut length = 0
  for byte in key {
    match self.find_child(node, byte) {
      None => break
      Some(child) => {
        node = child
        length += 1
        if self.terminals.get(node).unwrap() {
          best = Some(length)
        }
      }
    }
  }
  best
}

///|
/// All stored prefix byte lengths, shortest first, all-or-error on budget.
/// Callers implementing routes must define their own separator boundaries.
pub fn Trie::prefix_lengths(
  self : Trie,
  key : Bytes,
  max_matches? : Int = 4096,
) -> Array[Int] raise @support.SuccinctError {
  if max_matches < 0 {
    raise @support.SuccinctError::InvalidArgument(
      context="prefix match budget",
      detail="must be non-negative",
    )
  }
  let result : Array[Int] = []
  let mut node = 0
  let mut length = 0
  while true {
    if self.terminals.get(node).unwrap() {
      if result.length() >= max_matches {
        raise @support.SuccinctError::InvalidArgument(
          context="prefix match budget",
          detail="too many matches",
        )
      }
      result.push(length)
    }
    if length == key.length() {
      break
    }
    match self.find_child(node, key[length]) {
      None => break
      Some(child) => {
        node = child
        length += 1
      }
    }
  }
  result
}
