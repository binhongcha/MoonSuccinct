///|
/// Half-open index range within an Elias–Fano sequence.
pub(all) struct IndexRange {
  start : Int
  end : Int
} derive(Debug, Eq)

///|
/// First index whose value is greater than or equal to target.
pub fn EliasFano::lower_bound(self : EliasFano, target : UInt64) -> Int {
  let mut low = 0
  let mut high = self.length
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

///|
/// First index whose value is strictly greater than target.
pub fn EliasFano::upper_bound(self : EliasFano, target : UInt64) -> Int {
  let mut low = 0
  let mut high = self.length
  while low < high {
    let middle = low + (high - low) / 2
    if self.get(middle).unwrap() <= target {
      low = middle + 1
    } else {
      high = middle
    }
  }
  low
}

///|
/// Half-open range containing every occurrence of target.
pub fn EliasFano::equal_range(self : EliasFano, target : UInt64) -> IndexRange {
  { start: self.lower_bound(target), end: self.upper_bound(target), }
}

///|
/// Whether at least one occurrence of target is present.
pub fn EliasFano::contains(self : EliasFano, target : UInt64) -> Bool {
  let index = self.lower_bound(target)
  index < self.length && self.get(index).unwrap() == target
}

///|
/// Number of occurrences of target.
pub fn EliasFano::count(self : EliasFano, target : UInt64) -> Int {
  let range = self.equal_range(target)
  range.end - range.start
}

///|
/// Largest represented value less than or equal to target.
pub fn EliasFano::predecessor(self : EliasFano, target : UInt64) -> UInt64? {
  let end = self.upper_bound(target)
  if end == 0 {
    None
  } else {
    self.get(end - 1)
  }
}

///|
/// Smallest represented value greater than or equal to target.
pub fn EliasFano::successor(self : EliasFano, target : UInt64) -> UInt64? {
  self.get(self.lower_bound(target))
}

///|
/// Largest represented value strictly less than target.
pub fn EliasFano::strict_predecessor(
  self : EliasFano,
  target : UInt64,
) -> UInt64? {
  let start = self.lower_bound(target)
  if start == 0 {
    None
  } else {
    self.get(start - 1)
  }
}

///|
/// Smallest represented value strictly greater than target.
pub fn EliasFano::strict_successor(
  self : EliasFano,
  target : UInt64,
) -> UInt64? {
  self.get(self.upper_bound(target))
}
