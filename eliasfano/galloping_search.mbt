///|
/// First index at or after `start` whose value is at least `target`.
/// Exponential window growth makes a nearby posting-list seek logarithmic in
/// the distance advanced, while retaining the ordinary O(log n) worst case.
pub fn EliasFano::lower_bound_from(
  self : EliasFano,
  start : Int,
  target : UInt64,
) -> Int raise @support.SuccinctError {
  if start < 0 || start > self.length {
    raise @support.SuccinctError::OutOfRange(
      context="Elias-Fano seek start",
      index=start,
      length=self.length,
    )
  }
  let remaining = self.length - start
  let mut low = start
  let mut span = 1
  let mut high = if span >= remaining { self.length } else { start + span }
  while high < self.length && self.get(high - 1).unwrap() < target {
    low = high
    span = if span > remaining / 2 { remaining } else { span * 2 }
    high = if span >= remaining { self.length } else { start + span }
  }
  while low < high {
    let middle = low + (high - low) / 2
    if self.get(middle).unwrap() < target {
      low = middle + 1
    } else {
      high = middle
    }
  }
  low
}
