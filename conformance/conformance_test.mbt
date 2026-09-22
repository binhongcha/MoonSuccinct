///|
fn generated_term(seed : Int) -> Bytes {
  Bytes::from_array([
    ((seed * 17 + 3) % 251).to_byte(),
    ((seed / 3 + 11) % 251).to_byte(),
    ((seed * seed + 7) % 251).to_byte(),
    ((seed * 29 + seed / 5) % 251).to_byte(),
  ])
}

///|
fn generated_terms(count : Int) -> Array[Bytes] {
  let terms : Array[Bytes] = [b""]
  for index = count - 1; index >= 0; index = index - 1 {
    let term = generated_term(index)
    terms.push(term)
    if index % 9 == 0 {
      terms.push(term)
    }
  }
  terms.push(b"a")
  terms.push(b"ab")
  terms.push(b"abc")
  terms.push(b"abc")
  terms.push(b"abd")
  terms
}

///|
fn expected_prefix(terms : Array[Bytes], prefix : Bytes) -> Array[Bytes] {
  let output : Array[Bytes] = []
  for term in terms {
    if term.length() >= prefix.length() {
      let mut matches = true
      for index = 0; index < prefix.length(); index = index + 1 {
        if term[index] != prefix[index] {
          matches = false
          break
        }
      }
      if matches {
        output.push(term)
      }
    }
  }
  output
}

///|
fn reference_lower_bound(terms : Array[Bytes], target : Bytes) -> Int {
  let mut index = 0
  while index < terms.length() {
    let term = terms[index]
    let common = if term.length() < target.length() {
      term.length()
    } else {
      target.length()
    }
    let mut comparison = 0
    for offset = 0; offset < common; offset = offset + 1 {
      if term[offset].to_int() < target[offset].to_int() {
        comparison = -1
        break
      } else if term[offset].to_int() > target[offset].to_int() {
        comparison = 1
        break
      }
    }
    if comparison == 0 {
      if term.length() < target.length() {
        comparison = -1
      } else if term.length() > target.length() {
        comparison = 1
      }
    }
    if comparison >= 0 {
      return index
    }
    index += 1
  }
  terms.length()
}

///|
test "LOUDS trie and front-coded dictionary share a canonical term order" {
  let input = generated_terms(320)
  let dictionary = @frontcoded.from_terms(input, block_size=11)
  let trie = @louds.trie_from_terms(input)
  let dictionary_terms = dictionary.to_terms()
  let trie_terms = trie.terms_with_prefix(b"", 1000)
  assert_eq(dictionary_terms, trie_terms)
  assert_eq(dictionary.length(), trie.term_count())
  for index = 0; index < dictionary_terms.length(); index = index + 1 {
    let term = dictionary_terms[index]
    assert_eq(dictionary.term_number(term), Some(index))
    assert_eq(trie.term_number(term), Some(index))
    assert_true(dictionary.contains(term))
    assert_true(trie.contains(term))
  }
}

///|
test "prefix enumeration agrees across structures and a simple oracle" {
  let input = generated_terms(180)
  let dictionary = @frontcoded.from_terms(input, block_size=7)
  let trie = @louds.trie_from_terms(input)
  let sorted = dictionary.to_terms()
  let prefixes : Array[Bytes] = [
    b"",
    b"a",
    b"ab",
    b"abc",
    b"z",
    Bytes::from_array([b'\x00']),
    Bytes::from_array([b'\xfa']),
  ]
  for prefix in prefixes {
    let expected = expected_prefix(sorted, prefix)
    assert_eq(dictionary.terms_with_prefix(prefix, 1000), expected)
    assert_eq(trie.terms_with_prefix(prefix, 1000), expected)
    assert_eq(
      dictionary.prefix_range(prefix).end -
      dictionary.prefix_range(prefix).start,
      expected.length(),
    )
    assert_eq(
      trie.prefix_range(prefix).end - trie.prefix_range(prefix).start,
      expected.length(),
    )
  }
}

///|
test "front-coded restart sizes do not change observable behavior" {
  let input = generated_terms(140)
  let baseline = @frontcoded.from_terms(input, block_size=1)
  let expected = baseline.to_terms()
  let sizes = [1, 2, 3, 8, 31, 256]
  for block_size in sizes {
    let dictionary = @frontcoded.from_terms(input, block_size~)
    assert_eq(dictionary.to_terms(), expected)
    for index = 0; index < expected.length(); index = index + 1 {
      assert_eq(dictionary.get(index), Some(expected[index]))
    }
  }
}

///|
test "canonical codecs are deterministic after reconstruction" {
  let terms = generated_terms(120)
  let dictionary = @frontcoded.from_terms(terms, block_size=9)
  let dictionary_bytes = @frontcoded.encode(dictionary)
  assert_eq(
    @frontcoded.encode(@frontcoded.decode(dictionary_bytes)),
    dictionary_bytes,
  )
  let trie = @louds.trie_from_terms(terms)
  let trie_bytes = @louds.encode_trie(trie)
  assert_eq(@louds.encode_trie(@louds.decode_trie(trie_bytes)), trie_bytes)
  let values : Array[UInt64] = []
  let mut current = 0UL
  for index = 0; index < 500; index = index + 1 {
    current += ((index * 31 + 7) % 19).to_uint64()
    values.push(current)
  }
  let sequence = @eliasfano.from_values(values)
  let sequence_bytes = @eliasfano.encode(sequence)
  assert_eq(
    @eliasfano.encode(@eliasfano.decode(sequence_bytes)),
    sequence_bytes,
  )
}

///|
test "Elias-Fano searches agree with a materialized sorted oracle" {
  let values : Array[UInt64] = []
  let mut current = 0UL
  for index = 0; index < 600; index = index + 1 {
    current += ((index * 13 + 5) % 7).to_uint64()
    values.push(current)
    if index % 17 == 0 {
      values.push(current)
    }
  }
  let sequence = @eliasfano.from_values(values)
  for target = 0; target < 1800; target = target + 3 {
    let target64 = target.to_uint64()
    let expected = {
      let mut index = 0
      while index < values.length() && values[index] < target64 {
        index += 1
      }
      index
    }
    assert_eq(sequence.lower_bound(target64), expected)
    assert_eq(
      sequence.contains(target64),
      expected < values.length() && values[expected] == target64,
    )
  }
}

///|
test "rank select and position ranges are mutual inverses" {
  let bits : Array[Bool] = []
  for index = 0; index < 1025; index = index + 1 {
    bits.push(index % 97 == 0 || index % 13 == 2 || index % 17 == 9)
  }
  let vector = @bitvector.from_bools(bits)
  let ones = vector.one_positions(0, vector.length())
  let zeros = vector.zero_positions(0, vector.length())
  assert_eq(ones.length(), vector.one_count())
  assert_eq(zeros.length(), vector.zero_count())
  for ordinal = 0; ordinal < ones.length(); ordinal = ordinal + 1 {
    let position = ones[ordinal]
    assert_eq(vector.select1(ordinal), Some(position))
    assert_eq(vector.rank1(position), ordinal)
    assert_eq(vector.next1(position), Some(position))
  }
  for ordinal = 0; ordinal < zeros.length(); ordinal = ordinal + 1 {
    let position = zeros[ordinal]
    assert_eq(vector.select0(ordinal), Some(position))
    assert_eq(vector.rank0(position), ordinal)
    assert_eq(vector.next0(position), Some(position))
  }
}

///|
test "dictionary lower bound agrees with independent byte comparison" {
  let dictionary = @frontcoded.from_terms(generated_terms(250), block_size=13)
  let terms = dictionary.to_terms()
  for seed = 0; seed < 400; seed = seed + 1 {
    let candidate = generated_term(seed)
    assert_eq(
      dictionary.lower_bound(candidate),
      reference_lower_bound(terms, candidate),
    )
  }
}
