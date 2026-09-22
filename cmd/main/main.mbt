///|
/// Run a deterministic, allocation-bounded smoke check over all public
/// structure families and print exact serialized sizes.
fn main raise {
  assert_true(@conformance.smoke_check())
  let bits = @bitvector.from_bools([
    true, false, true, false, false, true, false, true,
  ])
  let sequence = @eliasfano.from_values([1UL, 3UL, 3UL, 9UL, 27UL, 81UL, 243UL])
  let terms : Array[Bytes] = [
    b"api", b"api/admin", b"api/catalog", b"compile", b"config",
  ]
  let trie = @louds.trie_from_terms(terms)
  let dictionary = @frontcoded.from_terms(terms, block_size=3)
  assert_eq(sequence.successor(10UL), Some(27UL))
  assert_eq(trie.terms_with_prefix(b"api", 10).length(), 3)
  assert_eq(dictionary.terms_with_prefix(b"api", 10).length(), 3)
  let bit_report = bits.space_report()
  let sequence_report = sequence.space_report()
  let trie_report = trie.space_report()
  let dictionary_report = dictionary.space_report()
  println("MoonSuccinct \{@lib.version()} self-check: ok")
  println(
    "bitvector items=\{bit_report.logical_items} bytes=\{bit_report.serialized_bytes}",
  )
  println(
    "elias-fano items=\{sequence_report.logical_items} bytes=\{sequence_report.serialized_bytes}",
  )
  println(
    "LOUDS terms=\{trie_report.logical_items} bytes=\{trie_report.serialized_bytes}",
  )
  println(
    "front-coded terms=\{dictionary_report.logical_items} bytes=\{dictionary_report.serialized_bytes}",
  )
}
