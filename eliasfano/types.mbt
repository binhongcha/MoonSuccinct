///|
/// Immutable Elias–Fano representation of a monotone non-decreasing UInt64
/// sequence. Duplicates are represented and retain their positions.
pub struct EliasFano {
  length : Int
  maximum : UInt64?
  low_width : Int
  lows : @packed.PackedInts
  highs : @bitvector.BitVector
}

///|
fn floor_log2(value : UInt64) -> Int {
  let mut remaining = value
  let mut result = -1
  while remaining != 0UL {
    remaining = remaining >> 1
    result += 1
  }
  result
}

///|
fn low_width_for(maximum : UInt64, length : Int) -> Int {
  if length <= 0 {
    0
  } else {
    let ratio = maximum / length.to_uint64()
    let width = floor_log2(ratio)
    if width < 0 {
      0
    } else {
      width
    }
  }
}

///|
fn low_mask(width : Int) -> UInt64 {
  if width <= 0 {
    0UL
  } else if width >= 64 {
    0xffffffffffffffffUL
  } else {
    (1UL << width) - 1UL
  }
}
