///|
/// Lexicographic unsigned-byte comparison.
pub fn compare_bytes(left : Bytes, right : Bytes) -> Int {
  let common = if left.length() < right.length() {
    left.length()
  } else {
    right.length()
  }
  for i = 0; i < common; i = i + 1 {
    let a = left[i].to_int()
    let b = right[i].to_int()
    if a < b {
      return -1
    }
    if a > b {
      return 1
    }
  }
  if left.length() < right.length() {
    -1
  } else if left.length() > right.length() {
    1
  } else {
    0
  }
}

///|
/// Number of equal leading bytes shared by two terms.
pub fn common_prefix_length(left : Bytes, right : Bytes) -> Int {
  let common = if left.length() < right.length() {
    left.length()
  } else {
    right.length()
  }
  let mut index = 0
  while index < common && left[index] == right[index] {
    index += 1
  }
  index
}

///|
/// Whether `value` begins with the complete `prefix` byte sequence.
pub fn starts_with_bytes(value : Bytes, prefix : Bytes) -> Bool {
  if prefix.length() > value.length() {
    return false
  }
  for i = 0; i < prefix.length(); i = i + 1 {
    if value[i] != prefix[i] {
      return false
    }
  }
  true
}

///|
/// Own a byte-for-byte copy rather than retaining caller storage.
pub fn copy_bytes(value : Bytes) -> Bytes {
  let output : Array[Byte] = []
  for byte in value {
    output.push(byte)
  }
  Bytes::from_array(output)
}

///|
/// Concatenate a prefix slice and suffix into newly owned bytes.
pub fn join_prefix_suffix(
  base : Bytes,
  prefix_length : Int,
  suffix : Bytes,
) -> Bytes raise SuccinctError {
  if prefix_length < 0 || prefix_length > base.length() {
    raise InvalidArgument(
      context="prefix_length",
      detail="must address a prefix of base",
    )
  }
  let output : Array[Byte] = []
  for i = 0; i < prefix_length; i = i + 1 {
    output.push(base[i])
  }
  for byte in suffix {
    output.push(byte)
  }
  Bytes::from_array(output)
}
