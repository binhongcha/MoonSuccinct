///|
/// Create an empty incremental Elias–Fano builder.
pub fn EliasFanoBuilder::new() -> EliasFanoBuilder {
  { values: [], last: None, }
}

///|
/// Number of accepted values.
pub fn EliasFanoBuilder::length(self : EliasFanoBuilder) -> Int {
  self.values.length()
}

///|
/// Whether no values have been accepted.
pub fn EliasFanoBuilder::is_empty(self : EliasFanoBuilder) -> Bool {
  self.values.length() == 0
}

///|
/// Last accepted value, or `None` for an empty builder.
pub fn EliasFanoBuilder::last(self : EliasFanoBuilder) -> UInt64? {
  self.last
}

///|
/// Append one value, rejecting a monotonicity violation before mutating the
/// builder. Equal adjacent values are valid and retain distinct positions.
pub fn EliasFanoBuilder::push(
  self : EliasFanoBuilder,
  value : UInt64,
) -> Unit raise @support.SuccinctError {
  match self.last {
    Some(previous) if value < previous =>
      raise @support.SuccinctError::InvalidSequence(
        index=self.values.length(),
        detail="Elias-Fano input must be monotone non-decreasing",
      )
    _ => ()
  }
  self.values.push(value)
  self.last = Some(value)
}

///|
/// Append a batch in iteration order. Values accepted before a later invalid
/// value remain in the builder, matching ordinary streaming parser semantics.
pub fn EliasFanoBuilder::append_all(
  self : EliasFanoBuilder,
  values : Array[UInt64],
) -> Unit raise @support.SuccinctError {
  for value in values {
    self.push(value)
  }
}

///|
/// Return an owned copy of currently accepted logical values.
pub fn EliasFanoBuilder::to_values(self : EliasFanoBuilder) -> Array[UInt64] {
  let result : Array[UInt64] = []
  for value in self.values {
    result.push(value)
  }
  result
}

///|
/// Freeze the current sequence into an immutable Elias–Fano snapshot. Later
/// appends to the builder cannot affect a previously returned snapshot.
pub fn EliasFanoBuilder::finish(
  self : EliasFanoBuilder,
) -> EliasFano raise @support.SuccinctError {
  from_values(self.values)
}

///|
/// Remove all accepted values so the allocation can be reused.
pub fn EliasFanoBuilder::clear(self : EliasFanoBuilder) -> Unit {
  self.values.clear()
  self.last = None
}
