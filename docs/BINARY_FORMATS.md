# Binary formats

All multibyte fixed integers are unsigned little-endian. Counts and lengths use
canonical unsigned LEB128-style varints. Every top-level object starts with a
four-byte ASCII magic and one-byte version. Version 1 decoders reject unknown
versions and trailing bytes.

These formats are stable for `0.1.x`: an encoder update must either emit the
same canonical bytes for the same logical object or introduce a new version.

## Bit vector (`MSBV`, version 1)

| Field | Encoding |
| --- | --- |
| magic | bytes `MSBV` |
| version | byte `1` |
| logical bit length | varint |
| packed word count | varint |
| packed words | repeated little-endian `u64` |

Bits are least-significant-bit first within each word. Padding above the
logical length in the final word must be zero. Rank directories are derived and
are never serialized.

## Elias–Fano (`MSEF`, version 1)

| Field | Encoding |
| --- | --- |
| magic/version | `MSEF`, byte `1` |
| value count | varint |
| maximum-present flag | byte `0` or `1` |
| maximum | optional little-endian `u64` |
| low width | byte in `0..63` |
| low word count and words | varint, repeated `u64` |
| high logical bit length | varint |
| high word count and words | varint, repeated `u64` |

The decoder reconstructs values, checks monotonicity, checks one-count equals
the value count, and confirms the stored maximum.

## LOUDS trie (`MSTR`, version 1)

| Field | Encoding |
| --- | --- |
| magic/version | `MSTR`, byte `1` |
| topology | length-prefixed `MSBV` object |
| edge labels | length-prefixed raw bytes |
| terminal flags | length-prefixed `MSBV` object |

The topology must contain `n` zero terminators and `n - 1` child markers.
Label count must equal edge count, terminal count must equal node count, and
sibling labels must be strictly increasing.

## Front-coded dictionary (`MSFD`, version 1)

| Field | Encoding |
| --- | --- |
| magic/version | `MSFD`, byte `1` |
| term count | varint |
| restart block size | positive varint |
| record bytes | length-prefixed bytes |
| restart offset count | varint |
| restart offsets | repeated varint |

A restart record is `term_length, term_bytes`. A continuation record is
`shared_prefix_length, suffix_length, suffix_bytes`. Offsets must be strictly
increasing, every block must end exactly at the next offset, and decoded terms
must be strictly increasing in unsigned-byte lexicographic order.

## Compatibility policy

- Unknown versions fail with `MOONSUCCINCT_VERSION`.
- Malformed structure, noncanonical padding, or unconsumed bytes fail with
  `MOONSUCCINCT_ENCODING` or `MOONSUCCINCT_TRUNCATED`.
- Resource ceilings fail with `MOONSUCCINCT_RESOURCE_LIMIT`; callers may retry
  with explicitly larger validated limits.
- Encodings are portable data, but they are not a framing protocol. A stream or
  file container must supply object boundaries and authentication if required.
