///|
let trie_magic : Bytes = b"MSTR"

///|
let trie_version : Int = 1

///|
/// Encode topology, edge labels, and terminal bits deterministically.
pub fn encode_trie(trie : Trie) -> Bytes {
  let writer = @binary.Writer::new()
  writer.write_bytes(trie_magic)
  writer.write_byte(trie_version.to_byte())
  writer.write_length_prefixed(@bitvector.encode(trie.topology.bits))
  writer.write_length_prefixed(trie.edge_labels)
  writer.write_length_prefixed(@bitvector.encode(trie.terminals))
  writer.finish()
}

///|
/// Decode a stable trie representation and revalidate all cross-field
/// invariants, including sorted sibling labels.
pub fn decode_trie(
  data : Bytes,
  limits? : @support.DecodeLimits = @support.DecodeLimits::sensible(),
) -> Trie raise @support.SuccinctError {
  let reader = @binary.Reader::new(data, limits~)
  reader.read_magic(trie_magic, "LOUDS trie")
  let version = reader.read_byte(context="LOUDS trie version").to_int()
  if version != trie_version {
    raise @support.SuccinctError::UnsupportedVersion(
      format="LOUDS trie",
      version~,
    )
  }
  let topology_bytes = reader.read_term("LOUDS topology")
  let topology = from_bitvector(@bitvector.decode(topology_bytes, limits~))
  let labels = reader.read_term("LOUDS edge labels")
  let terminal_bytes = reader.read_term("LOUDS terminals")
  let terminals = @bitvector.decode(terminal_bytes, limits~)
  reader.finish("LOUDS trie")
  trie_from_parts(topology, labels, terminals)
}
