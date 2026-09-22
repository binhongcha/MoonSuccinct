///|
fn validate_value_range(
  lower : UInt64,
  upper : UInt64,
) -> Unit raise @support.SuccinctError {
  if upper < lower {
    raise @support.SuccinctError::InvalidArgument(
      context="Elias-Fano value range",
      detail="expected lower <= upper",
    )
  }
}

///|
/// Indices of values in the half-open interval `[lower, upper)`.
pub fn EliasFano::range(
  self : EliasFano,
  lower : UInt64,
  upper : UInt64,
) -> IndexRange raise @support.SuccinctError {
  validate_value_range(lower, upper)
  { start: self.lower_bound(lower), end: self.lower_bound(upper), }
}

///|
/// Number of represented values in `[lower, upper)`, including duplicates.
pub fn EliasFano::count_range(
  self : EliasFano,
  lower : UInt64,
  upper : UInt64,
) -> Int raise @support.SuccinctError {
  let selected = self.range(lower, upper)
  selected.end - selected.start
}

///|
/// Copy an indexed half-open slice into a new immutable Elias–Fano sequence.
pub fn EliasFano::slice(
  self : EliasFano,
  start : Int,
  end : Int,
) -> EliasFano raise @support.SuccinctError {
  if start < 0 || start > self.length {
    raise @support.SuccinctError::OutOfRange(
      context="Elias-Fano slice start",
      index=start,
      length=self.length,
    )
  }
  if end < start || end > self.length {
    raise @support.SuccinctError::InvalidArgument(
      context="Elias-Fano slice end",
      detail="expected start <= end <= sequence length",
    )
  }
  let values : Array[UInt64] = []
  for index = start; index < end; index = index + 1 {
    values.push(self.get(index).unwrap())
  }
  from_values(values)
}

///|
/// Copy at most `limit` values from `[lower, upper)`. A zero limit performs
/// no logical value access and returns an empty array.
pub fn EliasFano::values_in_range(
  self : EliasFano,
  lower : UInt64,
  upper : UInt64,
  limit : Int,
) -> Array[UInt64] raise @support.SuccinctError {
  if limit < 0 {
    raise @support.SuccinctError::InvalidArgument(
      context="Elias-Fano range limit",
      detail="must be non-negative",
    )
  }
  let selected = self.range(lower, upper)
  let stop = if selected.end - selected.start > limit {
    selected.start + limit
  } else {
    selected.end
  }
  let values : Array[UInt64] = []
  for index = selected.start; index < stop; index = index + 1 {
    values.push(self.get(index).unwrap())
  }
  values
}
