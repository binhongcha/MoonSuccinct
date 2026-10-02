///|
/// Distinct intersection optimized for posting lists with very different
/// cardinalities. Each distinct value of the shorter list seeks forward in
/// the longer list, avoiding a full scan of long gaps. For similarly sized
/// inputs `intersect_distinct` is usually preferable because its merge has
/// lower constant overhead.
pub fn intersect_distinct_skewed(
  left : EliasFano,
  right : EliasFano,
) -> EliasFano raise @support.SuccinctError {
  let (shorter, longer) = if left.length <= right.length {
    (left, right)
  } else {
    (right, left)
  }
  let values : Array[UInt64] = []
  let mut longer_index = 0
  for index = 0; index < shorter.length; index = index + 1 {
    let value = shorter.get(index).unwrap()
    if index > 0 && value == shorter.get(index - 1).unwrap() {
      continue
    }
    longer_index = longer.lower_bound_from(longer_index, value)
    if longer_index >= longer.length {
      break
    }
    if longer.get(longer_index).unwrap() == value {
      values.push(value)
    }
  }
  from_values(values)
}
