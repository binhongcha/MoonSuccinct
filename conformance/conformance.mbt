///|
/// Identifier emitted by external harnesses that select this package.
pub let suite_name : String = "MoonSuccinct cross-structure conformance"

///|
/// Minimal embeddable health check covering every public structure family.
/// The comprehensive generated checks remain in this package's test suite.
pub fn smoke_check() -> Bool raise {
  let bits = @bitvector.from_bools([true, false, true])
  let values = @eliasfano.from_values([1UL, 2UL, 8UL])
  let terms : Array[Bytes] = [b"a", b"ab", b"b"]
  let dictionary = @frontcoded.from_terms(terms, block_size=2)
  let trie = @louds.trie_from_terms(terms)
  bits.rank1(3) == 2 &&
  values.successor(3UL) == Some(8UL) &&
  dictionary.terms_with_prefix(b"a", 10) == [b"a", b"ab"] &&
  trie.terms_with_prefix(b"a", 10) == [b"a", b"ab"]
}
