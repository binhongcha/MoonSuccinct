///|
fn main raise {
  // Sorted document identifiers from an inverted-list style workload.
  let documents : Array[UInt64] = [
    2UL, 5UL, 5UL, 21UL, 144UL, 1000UL, 1000000UL,
  ]
  let postings = @eliasfano.from_values(documents)
  assert_eq(postings.to_values(), documents)
  assert_true(postings.contains(144UL))
  assert_false(postings.contains(145UL))
  assert_eq(postings.predecessor(500UL), Some(144UL))
  assert_eq(postings.successor(500UL), Some(1000UL))
  let duplicates = postings.equal_range(5UL)
  assert_eq(duplicates.start, 1)
  assert_eq(duplicates.end, 3)
  let restored = @eliasfano.decode(@eliasfano.encode(postings))
  assert_eq(restored.to_values(), documents)
  let report = postings.space_report()
  println(
    "postings=\{report.logical_items} accounted_bits=\{report.accounted_bits()} serialized_bytes=\{report.serialized_bytes}",
  )
}
