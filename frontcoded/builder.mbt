///|
/// Build a dictionary after sorting and deduplicating arbitrary byte terms.
pub fn from_terms(
  input : Array[Bytes],
  block_size? : Int = 8,
) -> Dictionary raise @support.SuccinctError {
  if block_size <= 0 {
    raise @support.SuccinctError::InvalidArgument(
      context="front-coded block size",
      detail="must be positive",
    )
  }
  let terms = copy_terms(input)
  sort_terms(terms)
  let distinct = deduplicate_sorted(terms)
  let writer = @binary.Writer::new()
  let block_offsets : Array[Int] = []
  let mut previous = b""
  for index = 0; index < distinct.length(); index = index + 1 {
    let term = distinct[index]
    if index % block_size == 0 {
      block_offsets.push(writer.length())
      writer.write_length_prefixed(term)
    } else {
      let shared = @support.common_prefix_length(previous, term)
      writer.write_varint(shared.to_uint64())
      let suffix : Array[Byte] = []
      for offset = shared; offset < term.length(); offset = offset + 1 {
        suffix.push(term[offset])
      }
      writer.write_length_prefixed(Bytes::from_array(suffix))
    }
    previous = term
  }
  {
    terms: distinct.length(),
    block_size,
    encoded: writer.finish(),
    block_offsets,
  }
}

///|
/// Reconstruct parts while validating every record and sorted invariant.
fn from_parts(
  terms : Int,
  block_size : Int,
  encoded : Bytes,
  block_offsets : Array[Int],
) -> Dictionary raise @support.SuccinctError {
  if terms < 0 || block_size <= 0 {
    raise @support.SuccinctError::InvalidArgument(
      context="front-coded metadata",
      detail="invalid term count or block size",
    )
  }
  let expected_blocks = if terms == 0 {
    0
  } else {
    (terms + block_size - 1) / block_size
  }
  if block_offsets.length() != expected_blocks {
    raise @support.SuccinctError::InvalidArgument(
      context="front-coded block offsets",
      detail="block count does not match term count",
    )
  }
  let copied_offsets : Array[Int] = []
  for index = 0; index < block_offsets.length(); index = index + 1 {
    let offset = block_offsets[index]
    if offset < 0 ||
      offset >= encoded.length() ||
      (index > 0 && offset <= block_offsets[index - 1]) {
      raise @support.SuccinctError::InvalidSequence(
        index~,
        detail="block offsets must be increasing encoded positions",
      )
    }
    copied_offsets.push(offset)
  }
  let candidate = {
    terms,
    block_size,
    encoded: @support.copy_bytes(encoded),
    block_offsets: copied_offsets,
  }
  let mut previous : Bytes? = None
  for index = 0; index < terms; index = index + 1 {
    let term = candidate.at(index)
    match previous {
      Some(value) =>
        if @support.compare_bytes(value, term) >= 0 {
          raise @support.SuccinctError::InvalidSequence(
            index~,
            detail="decoded terms must be strictly increasing",
          )
        }
      None => ()
    }
    previous = Some(term)
  }
  candidate
}
