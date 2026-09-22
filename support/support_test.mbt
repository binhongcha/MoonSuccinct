///|
test "byte helpers use unsigned lexicographic order" {
  assert_eq(compare_bytes(b"a", b"aa"), -1)
  assert_eq(compare_bytes(b"aa", b"a"), 1)
  assert_eq(compare_bytes(b"same", b"same"), 0)
  assert_eq(compare_bytes(Bytes::from_array([255]), b"z"), 1)
  assert_eq(common_prefix_length(b"prefix-a", b"prefix-b"), 7)
  assert_true(starts_with_bytes(b"prefix-a", b"prefix"))
  assert_false(starts_with_bytes(b"pre", b"prefix"))
}

///|
test "limits reject excess without rejecting their boundary" {
  let limits = DecodeLimits::new(4, 3, 2, 5)
  limits.check_input(4)
  limits.check_items(3)
  limits.check_term(2)
  limits.check_total_terms(5)
  limits.check_items(4) catch {
    ResourceLimit(limit~, actual~, maximum~) => {
      assert_eq(limit, "items")
      assert_eq(actual, 4L)
      assert_eq(maximum, 3L)
    }
    _ => fail("expected resource limit")
  }
}

///|
test "space report distinguishes payload and auxiliary bits" {
  let report = SpaceReport::new("sample", 4, 9L, 8L, 12)
  assert_eq(report.accounted_bits(), 17L)
  assert_eq(report.accounted_bytes(), 3L)
  assert_eq(report.bits_per_item(), 4.25)
  assert_eq(SpaceReport::new("empty", 0, 0L, 0L, 0).bits_per_item(), 0.0)
}
