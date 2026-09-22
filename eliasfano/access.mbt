///|
/// Number of represented values.
pub fn EliasFano::length(self : EliasFano) -> Int {
  self.length
}

///|
/// Whether the sequence is empty.
pub fn EliasFano::is_empty(self : EliasFano) -> Bool {
  self.length == 0
}

///|
/// Selected low-bit width.
pub fn EliasFano::low_width(self : EliasFano) -> Int {
  self.low_width
}

///|
/// Maximum represented value, absent for an empty sequence.
pub fn EliasFano::maximum(self : EliasFano) -> UInt64? {
  self.maximum
}

///|
/// Minimum represented value, absent for an empty sequence.
pub fn EliasFano::minimum(self : EliasFano) -> UInt64? {
  self.get(0)
}

///|
/// Optional indexed access.
pub fn EliasFano::get(self : EliasFano, index : Int) -> UInt64? {
  if index < 0 || index >= self.length {
    return None
  }
  let high_position = self.highs.select1(index).unwrap()
  let high = (high_position - index).to_uint64()
  let low = self.lows.get(index).unwrap()
  Some((high << self.low_width) | low)
}

///|
/// Checked indexed access.
pub fn EliasFano::at(
  self : EliasFano,
  index : Int,
) -> UInt64 raise @support.SuccinctError {
  match self.get(index) {
    Some(value) => value
    None =>
      raise @support.SuccinctError::OutOfRange(
        context="Elias-Fano value",
        index~,
        length=self.length,
      )
  }
}

///|
/// Materialize the logical sequence for interoperation or differential tests.
pub fn EliasFano::to_values(self : EliasFano) -> Array[UInt64] {
  let values : Array[UInt64] = []
  for index = 0; index < self.length; index = index + 1 {
    values.push(self.get(index).unwrap())
  }
  values
}

///|
/// Owned canonical low packed words for serialization adapters.
pub fn EliasFano::low_words(self : EliasFano) -> Array[UInt64] {
  self.lows.packed_words()
}

///|
/// Logical length of the unary high-bit vector.
pub fn EliasFano::high_bit_length(self : EliasFano) -> Int {
  self.highs.length()
}

///|
/// Owned canonical unary high packed words for serialization adapters.
pub fn EliasFano::high_words(self : EliasFano) -> Array[UInt64] {
  self.highs.packed_words()
}
