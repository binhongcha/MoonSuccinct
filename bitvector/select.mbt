///|
fn BitVector::rank_target_valid(
  self : BitVector,
  position : Int,
  target : Bool,
) -> Int {
  if target {
    self.rank1_valid(position)
  } else {
    position - self.rank1_valid(position)
  }
}

///|
fn BitVector::target_count(self : BitVector, target : Bool) -> Int {
  if target {
    self.ones
  } else {
    self.length - self.ones
  }
}

///|
fn BitVector::select_target(
  self : BitVector,
  occurrence : Int,
  target : Bool,
) -> Int? {
  if occurrence < 0 || occurrence >= self.target_count(target) {
    return None
  }
  let mut low = 0
  let mut high = self.words.length()
  while low < high {
    let middle = low + (high - low) / 2
    let end = if (middle + 1) * word_bits < self.length {
      (middle + 1) * word_bits
    } else {
      self.length
    }
    if self.rank_target_valid(end, target) > occurrence {
      high = middle
    } else {
      low = middle + 1
    }
  }
  if low >= self.words.length() {
    return None
  }
  let word_index = low
  let start = word_index * word_bits
  let before = self.rank_target_valid(start, target)
  let wanted_in_word = occurrence - before
  let valid = valid_bits_in_word(self.length, word_index)
  let mut seen = 0
  for bit_offset = 0; bit_offset < valid; bit_offset = bit_offset + 1 {
    let bit = ((self.words[word_index] >> bit_offset) & 1UL) == 1UL
    if bit == target {
      if seen == wanted_in_word {
        return Some(start + bit_offset)
      }
      seen += 1
    }
  }
  None
}

///|
/// Position of the zero-based one-bit occurrence, or None when absent.
pub fn BitVector::select1(self : BitVector, occurrence : Int) -> Int? {
  self.select_target(occurrence, true)
}

///|
/// Position of the zero-based zero-bit occurrence, or None when absent.
pub fn BitVector::select0(self : BitVector, occurrence : Int) -> Int? {
  self.select_target(occurrence, false)
}

///|
/// First one bit at or after position.
pub fn BitVector::next1(
  self : BitVector,
  position : Int,
) -> Int? raise @support.SuccinctError {
  if position < 0 || position > self.length {
    raise @support.SuccinctError::OutOfRange(
      context="next1 position",
      index=position,
      length=self.length + 1,
    )
  }
  if position == self.length {
    None
  } else {
    self.select1(self.rank1(position))
  }
}

///|
/// First zero bit at or after position.
pub fn BitVector::next0(
  self : BitVector,
  position : Int,
) -> Int? raise @support.SuccinctError {
  if position < 0 || position > self.length {
    raise @support.SuccinctError::OutOfRange(
      context="next0 position",
      index=position,
      length=self.length + 1,
    )
  }
  if position == self.length {
    None
  } else {
    self.select0(self.rank0(position))
  }
}

///|
/// Last one bit strictly before position.
pub fn BitVector::previous1(
  self : BitVector,
  position : Int,
) -> Int? raise @support.SuccinctError {
  if position < 0 || position > self.length {
    raise @support.SuccinctError::OutOfRange(
      context="previous1 position",
      index=position,
      length=self.length + 1,
    )
  }
  let before = self.rank1(position)
  if before == 0 {
    None
  } else {
    self.select1(before - 1)
  }
}

///|
/// Last zero bit strictly before position.
pub fn BitVector::previous0(
  self : BitVector,
  position : Int,
) -> Int? raise @support.SuccinctError {
  if position < 0 || position > self.length {
    raise @support.SuccinctError::OutOfRange(
      context="previous0 position",
      index=position,
      length=self.length + 1,
    )
  }
  let before = self.rank0(position)
  if before == 0 {
    None
  } else {
    self.select0(before - 1)
  }
}
