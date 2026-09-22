///|
fn naive_lower(values : Array[UInt64], target : UInt64) -> Int {
  for index = 0; index < values.length(); index = index + 1 {
    if values[index] >= target {
      return index
    }
  }
  values.length()
}

///|
fn naive_upper(values : Array[UInt64], target : UInt64) -> Int {
  for index = 0; index < values.length(); index = index + 1 {
    if values[index] > target {
      return index
    }
  }
  values.length()
}

///|
fn generated_monotone(length : Int, salt : Int) -> Array[UInt64] {
  let values : Array[UInt64] = []
  let mut current = salt.to_uint64()
  for index = 0; index < length; index = index + 1 {
    current += ((index * 17 + salt * 13) % 5).to_uint64()
    values.push(current)
  }
  values
}

///|
test "bounds and membership match a plain monotone array" {
  let lengths = [0, 1, 2, 7, 64, 257]
  for length in lengths {
    let values = generated_monotone(length, 3)
    let encoded = from_values(values)
    let maximum = if length == 0 { 20UL } else { values[length - 1] + 3UL }
    let mut target = 0UL
    while target <= maximum {
      let lower = naive_lower(values, target)
      let upper = naive_upper(values, target)
      assert_eq(encoded.lower_bound(target), lower)
      assert_eq(encoded.upper_bound(target), upper)
      assert_eq(encoded.equal_range(target), { start: lower, end: upper, })
      assert_eq(encoded.contains(target), lower < upper)
      assert_eq(encoded.count(target), upper - lower)
      target += 1UL
    }
  }
}

///|
test "predecessor and successor define inclusive and strict variants" {
  let encoded = from_values([2UL, 4UL, 4UL, 9UL])
  assert_eq(encoded.predecessor(1UL), None)
  assert_eq(encoded.predecessor(2UL), Some(2UL))
  assert_eq(encoded.predecessor(4UL), Some(4UL))
  assert_eq(encoded.predecessor(8UL), Some(4UL))
  assert_eq(encoded.successor(0UL), Some(2UL))
  assert_eq(encoded.successor(4UL), Some(4UL))
  assert_eq(encoded.successor(10UL), None)
  assert_eq(encoded.strict_predecessor(4UL), Some(2UL))
  assert_eq(encoded.strict_successor(4UL), Some(9UL))
}

///|
test "search handles UInt64 endpoints without overflow" {
  let encoded = from_values([0UL, 0xffffffffffffffffUL])
  assert_eq(encoded.lower_bound(0xffffffffffffffffUL), 1)
  assert_eq(encoded.upper_bound(0xffffffffffffffffUL), 2)
  assert_eq(
    encoded.predecessor(0xffffffffffffffffUL),
    Some(0xffffffffffffffffUL),
  )
  assert_eq(encoded.successor(0xffffffffffffffffUL), Some(0xffffffffffffffffUL))
  assert_eq(encoded.strict_successor(0xffffffffffffffffUL), None)
}
