///|
fn push_distinct(output : Array[UInt64], value : UInt64) -> Unit {
  if output.length() == 0 || output[output.length() - 1] != value {
    output.push(value)
  }
}

///|
/// Sorted distinct intersection. Duplicate runs in either input contribute a
/// single value, which matches document-set and identifier-set semantics.
///
/// The merge performs at most `left.length + right.length` logical advances
/// and allocates only the result before constructing its immutable encoding.
pub fn intersect_distinct(
  left : EliasFano,
  right : EliasFano,
) -> EliasFano raise @support.SuccinctError {
  let values : Array[UInt64] = []
  let mut left_index = 0
  let mut right_index = 0
  while left_index < left.length && right_index < right.length {
    let left_value = left.get(left_index).unwrap()
    let right_value = right.get(right_index).unwrap()
    if left_value < right_value {
      left_index += 1
    } else if right_value < left_value {
      right_index += 1
    } else {
      push_distinct(values, left_value)
      left_index += 1
      right_index += 1
    }
  }
  from_values(values)
}

///|
/// Sorted distinct union. Every represented value appears once in the result.
pub fn union_distinct(
  left : EliasFano,
  right : EliasFano,
) -> EliasFano raise @support.SuccinctError {
  let values : Array[UInt64] = []
  let mut left_index = 0
  let mut right_index = 0
  while left_index < left.length || right_index < right.length {
    if left_index >= left.length {
      push_distinct(values, right.get(right_index).unwrap())
      right_index += 1
    } else if right_index >= right.length {
      push_distinct(values, left.get(left_index).unwrap())
      left_index += 1
    } else {
      let left_value = left.get(left_index).unwrap()
      let right_value = right.get(right_index).unwrap()
      if left_value < right_value {
        push_distinct(values, left_value)
        left_index += 1
      } else if right_value < left_value {
        push_distinct(values, right_value)
        right_index += 1
      } else {
        push_distinct(values, left_value)
        left_index += 1
        right_index += 1
      }
    }
  }
  from_values(values)
}

///|
/// Sorted distinct set difference `left - right`.
pub fn difference_distinct(
  left : EliasFano,
  right : EliasFano,
) -> EliasFano raise @support.SuccinctError {
  let values : Array[UInt64] = []
  let mut left_index = 0
  let mut right_index = 0
  while left_index < left.length {
    let left_value = left.get(left_index).unwrap()
    while right_index < right.length &&
          right.get(right_index).unwrap() < left_value {
      right_index += 1
    }
    if right_index >= right.length ||
      right.get(right_index).unwrap() != left_value {
      push_distinct(values, left_value)
    }
    left_index += 1
  }
  from_values(values)
}
