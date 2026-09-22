///|
fn main raise {
  // Compiler symbols, command names, metric names, and object-store keys are
  // all examples of immutable sorted dictionaries with repeated prefixes.
  let symbols : Array[Bytes] = [
    b"compile", b"compile.module", b"compile.module.parse", b"compile.module.typecheck",
    b"compile.package", b"config", b"config.load", b"config.validate",
  ]
  let dictionary = @frontcoded.from_terms(symbols, block_size=3)
  assert_eq(dictionary.to_terms(), symbols)
  assert_eq(dictionary.term_number(b"compile.package"), Some(4))
  assert_eq(dictionary.term_number(b"compile.unknown"), None)
  assert_eq(dictionary.terms_with_prefix(b"config.", 10), [
    b"config.load", b"config.validate",
  ])
  let restored = @frontcoded.decode(@frontcoded.encode(dictionary))
  assert_eq(restored.to_terms(), symbols)
  let report = dictionary.space_report()
  println(
    "symbols=\{report.logical_items} record_bytes=\{dictionary.encoded_bytes()} serialized_bytes=\{report.serialized_bytes}",
  )
}
