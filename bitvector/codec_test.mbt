///|
test "bit vectors round trip with derived rank directories" {
  let lengths = [0, 1, 63, 64, 65, 511, 512, 513, 1007]
  for length in lengths {
    let bits = patterned_bits(length, 23)
    let original = from_bools(bits)
    let encoded = encode(original)
    let decoded = decode(encoded)
    assert_eq(decoded.to_bools(), bits)
    assert_eq(decoded.one_count(), original.one_count())
    for position = 0; position <= length; position = position + 1 {
      assert_eq(decoded.rank1(position), original.rank1(position))
    }
    assert_eq(encode(decoded), encoded)
  }
}

///|
test "bit vector format is compact and versioned" {
  let vector = from_words([0x0123456789abcdefUL], 64)
  let encoded = encode(vector)
  assert_eq(encoded.length(), 15)
  assert_eq(encoded[0], b'M')
  assert_eq(encoded[1], b'S')
  assert_eq(encoded[2], b'B')
  assert_eq(encoded[3], b'V')
  assert_eq(encoded[4], 1)
}
