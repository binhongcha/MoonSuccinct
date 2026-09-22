///|
/// Portable accounting of one encoded structure.
pub(all) struct SpaceReport {
  structure : String
  logical_items : Int
  payload_bits : Int64
  auxiliary_bits : Int64
  serialized_bytes : Int
} derive(Debug, Eq)

///|
/// Construct a validated report.
pub fn SpaceReport::new(
  structure : String,
  logical_items : Int,
  payload_bits : Int64,
  auxiliary_bits : Int64,
  serialized_bytes : Int,
) -> SpaceReport raise SuccinctError {
  if logical_items < 0 ||
    payload_bits < 0L ||
    auxiliary_bits < 0L ||
    serialized_bytes < 0 {
    raise InvalidArgument(
      context="space report",
      detail="all counts must be non-negative",
    )
  }
  { structure, logical_items, payload_bits, auxiliary_bits, serialized_bytes, }
}

///|
/// Encoded payload plus query index metadata, excluding runtime object headers.
pub fn SpaceReport::accounted_bits(self : SpaceReport) -> Int64 {
  self.payload_bits + self.auxiliary_bits
}

///|
/// Ceiling of accounted bits expressed as bytes.
pub fn SpaceReport::accounted_bytes(self : SpaceReport) -> Int64 {
  (self.accounted_bits() + 7L) / 8L
}

///|
/// Accounted bits per logical item, or zero for an empty structure.
pub fn SpaceReport::bits_per_item(self : SpaceReport) -> Double {
  if self.logical_items == 0 {
    0.0
  } else {
    self.accounted_bits().to_double() / self.logical_items.to_double()
  }
}
