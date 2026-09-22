///|
/// Allocation and traversal ceilings for binary decoders.
pub(all) struct DecodeLimits {
  max_input_bytes : Int
  max_items : Int
  max_term_bytes : Int
  max_total_term_bytes : Int
} derive(Debug, Eq)

///|
/// Conservative defaults suitable for examples and ordinary indexes.
pub fn DecodeLimits::sensible() -> DecodeLimits {
  {
    max_input_bytes: 64 * 1024 * 1024,
    max_items: 10 * 1000 * 1000,
    max_term_bytes: 1024 * 1024,
    max_total_term_bytes: 64 * 1024 * 1024,
  }
}

///|
/// Construct validated custom decoder limits.
pub fn DecodeLimits::new(
  max_input_bytes : Int,
  max_items : Int,
  max_term_bytes : Int,
  max_total_term_bytes : Int,
) -> DecodeLimits raise SuccinctError {
  if max_input_bytes < 0 {
    raise InvalidArgument(
      context="max_input_bytes",
      detail="must be non-negative",
    )
  }
  if max_items < 0 {
    raise InvalidArgument(context="max_items", detail="must be non-negative")
  }
  if max_term_bytes < 0 {
    raise InvalidArgument(
      context="max_term_bytes",
      detail="must be non-negative",
    )
  }
  if max_total_term_bytes < 0 {
    raise InvalidArgument(
      context="max_total_term_bytes",
      detail="must be non-negative",
    )
  }
  { max_input_bytes, max_items, max_term_bytes, max_total_term_bytes, }
}

///|
/// Check an input byte length before reading fields from it.
pub fn DecodeLimits::check_input(
  self : DecodeLimits,
  actual : Int,
) -> Unit raise SuccinctError {
  if actual > self.max_input_bytes {
    raise ResourceLimit(
      limit="input_bytes",
      actual=actual.to_int64(),
      maximum=self.max_input_bytes.to_int64(),
    )
  }
}

///|
/// Check an item count before allocating item-sized storage.
pub fn DecodeLimits::check_items(
  self : DecodeLimits,
  actual : Int,
) -> Unit raise SuccinctError {
  if actual > self.max_items {
    raise ResourceLimit(
      limit="items",
      actual=actual.to_int64(),
      maximum=self.max_items.to_int64(),
    )
  }
}

///|
/// Check one decoded term length.
pub fn DecodeLimits::check_term(
  self : DecodeLimits,
  actual : Int,
) -> Unit raise SuccinctError {
  if actual > self.max_term_bytes {
    raise ResourceLimit(
      limit="term_bytes",
      actual=actual.to_int64(),
      maximum=self.max_term_bytes.to_int64(),
    )
  }
}

///|
/// Check the cumulative decoded term bytes.
pub fn DecodeLimits::check_total_terms(
  self : DecodeLimits,
  actual : Int,
) -> Unit raise SuccinctError {
  if actual > self.max_total_term_bytes {
    raise ResourceLimit(
      limit="total_term_bytes",
      actual=actual.to_int64(),
      maximum=self.max_total_term_bytes.to_int64(),
    )
  }
}
