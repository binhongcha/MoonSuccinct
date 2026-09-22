# MoonSuccinct

MoonSuccinct provides immutable indexes that preserve useful navigation and
search operations while keeping representation overhead measurable and small.

## Language

**Logical sequence**:
The values or bits represented by an index, independent of its encoded storage.
_Avoid_: Raw data, payload

**Succinct index**:
An immutable representation that combines compact encoded data with auxiliary
metadata for bounded navigation or search operations.
_Avoid_: Generic compression, archive

**Rank**:
The number of occurrences of a bit value in the half-open prefix ending at a
logical position.
_Avoid_: Count before, prefix count

**Select**:
The logical position of the occurrence identified by a zero-based occurrence
index.
_Avoid_: Find bit, nth bit

**Monotone sequence**:
A finite sequence of non-negative integers whose next value is never smaller
than its preceding value.
_Avoid_: Sorted set, because duplicates are permitted

**Node number**:
The breadth-first, zero-based identity of a node in a LOUDS topology.
_Avoid_: Node ID, offset

**Term number**:
The zero-based sorted position of a byte term in a static dictionary.
_Avoid_: Record ID, key ID

**Space report**:
A component-by-component accounting of encoded data and auxiliary index bits.
_Avoid_: Compression ratio, unless a baseline is stated

**Static query object**:
An immutable index produced after a finite build phase and used for repeated
queries without in-place logical updates.
_Avoid_: Read-only database, frozen collection

**Restart block**:
A consecutive group of sorted terms whose first term is independently
recoverable and bounds reconstruction work for later terms in the group.
_Avoid_: Page, chunk

**Canonical encoding**:
The single accepted byte representation for one logical object at a specified
format version; alternate padding, overlong integers, gaps, and trailing data
are invalid even if a permissive reader could recover the same values.
_Avoid_: Valid serialization

**Decode budget**:
Caller-selected ceilings on untrusted encoded input, item counts, individual
term size, and cumulative decoded term bytes.
_Avoid_: Memory limit, because CPU and traversal exposure are also bounded
