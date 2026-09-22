///|
/// Stable error categories returned by MoonSuccinct packages.
pub(all) suberror SuccinctError {
  InvalidArgument(context~ : String, detail~ : String)
  InvalidSequence(index~ : Int, detail~ : String)
  OutOfRange(context~ : String, index~ : Int, length~ : Int)
  NumericOverflow(context~ : String)
  TruncatedInput(offset~ : Int, context~ : String)
  InvalidEncoding(offset~ : Int, context~ : String, detail~ : String)
  ResourceLimit(limit~ : String, actual~ : Int64, maximum~ : Int64)
  UnsupportedVersion(format~ : String, version~ : Int)
} derive(Debug, Eq)

///|
/// Stable machine-readable code for integrations and tests.
pub fn SuccinctError::code(self : SuccinctError) -> String {
  match self {
    InvalidArgument(..) => "MOONSUCCINCT_ARGUMENT"
    InvalidSequence(..) => "MOONSUCCINCT_SEQUENCE"
    OutOfRange(..) => "MOONSUCCINCT_RANGE"
    NumericOverflow(..) => "MOONSUCCINCT_OVERFLOW"
    TruncatedInput(..) => "MOONSUCCINCT_TRUNCATED"
    InvalidEncoding(..) => "MOONSUCCINCT_ENCODING"
    ResourceLimit(..) => "MOONSUCCINCT_RESOURCE_LIMIT"
    UnsupportedVersion(..) => "MOONSUCCINCT_VERSION"
  }
}

///|
/// Human-readable error detail. Callers should branch on `code` or variants.
pub fn SuccinctError::message(self : SuccinctError) -> String {
  match self {
    InvalidArgument(context~, detail~) => "invalid \{context}: \{detail}"
    InvalidSequence(index~, detail~) =>
      "invalid sequence at index \{index}: \{detail}"
    OutOfRange(context~, index~, length~) =>
      "\{context} index \{index} is outside length \{length}"
    NumericOverflow(context~) => "numeric overflow while computing \{context}"
    TruncatedInput(offset~, context~) =>
      "truncated input at byte \{offset} while reading \{context}"
    InvalidEncoding(offset~, context~, detail~) =>
      "invalid \{context} encoding at byte \{offset}: \{detail}"
    ResourceLimit(limit~, actual~, maximum~) =>
      "resource limit \{limit} exceeded: \{actual} > \{maximum}"
    UnsupportedVersion(format~, version~) =>
      "unsupported \{format} version \{version}"
  }
}

///|
/// True when retrying with a larger decode limit may succeed unchanged.
pub fn SuccinctError::is_limit_error(self : SuccinctError) -> Bool {
  self is ResourceLimit(..)
}

///|
/// True for errors caused by externally supplied encoded bytes.
pub fn SuccinctError::is_malformed_input(self : SuccinctError) -> Bool {
  match self {
    TruncatedInput(..) | InvalidEncoding(..) | UnsupportedVersion(..) => true
    _ => false
  }
}
