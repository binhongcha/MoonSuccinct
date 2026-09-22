///|
fn validate_range(
  vector : BitVector,
  start : Int,
  end : Int,
) -> Unit raise @support.SuccinctError {
  if start < 0 || start > vector.length {
    raise @support.SuccinctError::OutOfRange(
      context="bit range start",
      index=start,
      length=vector.length,
    )
  }
  if end < start || end > vector.length {
    raise @support.SuccinctError::InvalidArgument(
      context="bit range end",
      detail="must satisfy start <= end <= vector length",
    )
  }
}

///|
/// Number of one bits in the half-open range `[start, end)`.
pub fn BitVector::ones_in(
  self : BitVector,
  start : Int,
  end : Int,
) -> Int raise @support.SuccinctError {
  validate_range(self, start, end)
  self.rank1(end) - self.rank1(start)
}

///|
/// Number of zero bits in the half-open range `[start, end)`.
pub fn BitVector::zeros_in(
  self : BitVector,
  start : Int,
  end : Int,
) -> Int raise @support.SuccinctError {
  validate_range(self, start, end)
  end - start - self.ones_in(start, end)
}

///|
/// Materialize one-bit positions in `[start, end)`. Work is proportional to
/// the number of returned positions rather than the range width.
pub fn BitVector::one_positions(
  self : BitVector,
  start : Int,
  end : Int,
) -> Array[Int] raise @support.SuccinctError {
  validate_range(self, start, end)
  let result : Array[Int] = []
  let first = self.rank1(start)
  let stop = self.rank1(end)
  for ordinal = first; ordinal < stop; ordinal = ordinal + 1 {
    result.push(self.select1(ordinal).unwrap())
  }
  result
}

///|
/// Materialize zero-bit positions in `[start, end)`. Work is proportional to
/// the number of returned positions rather than the range width.
pub fn BitVector::zero_positions(
  self : BitVector,
  start : Int,
  end : Int,
) -> Array[Int] raise @support.SuccinctError {
  validate_range(self, start, end)
  let result : Array[Int] = []
  let first = self.rank0(start)
  let stop = self.rank0(end)
  for ordinal = first; ordinal < stop; ordinal = ordinal + 1 {
    result.push(self.select0(ordinal).unwrap())
  }
  result
}
