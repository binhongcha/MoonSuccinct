# Architecture

MoonSuccinct is a set of immutable, portable indexing primitives. Package
boundaries follow data ownership and validation boundaries instead of placing
every structure behind one facade.

## Dependency direction

```text
support        binary
   │             │
   ├──────┬──────┘
   │      │
packed  bitvector
   │      │
   └──┬───┴──────────────┐
      │                  │
 eliasfano             louds

binary + support ───── frontcoded

all public families ── conformance
```

- `support` defines stable error categories, byte helpers, resource limits,
  and portable space accounting.
- `binary` owns bounded little-endian and varint readers/writers. It knows no
  particular succinct structure.
- `packed` stores fixed-width unsigned integers without a per-value object.
- `bitvector` owns packed bits, two-level rank directories, select, sparse
  navigation, validation, and its stable format.
- `eliasfano` composes packed low bits and a unary high-bit vector. It adds
  monotone construction, indexed/search/range queries, and distinct set
  algebra.
- `louds` composes bit vectors into a rooted ordered topology and a static byte
  trie.
- `frontcoded` is independent of LOUDS and compresses a sorted byte dictionary
  using restart blocks.
- `conformance` checks behavior that two or more structure families must share.

No package imports examples, command-line code, filesystem APIs, clocks, random
sources, or network APIs. The core therefore checks on Wasm, Wasm-GC,
JavaScript, and Native.

## Ownership model

Public constructors copy or encode caller-owned arrays and bytes. Public
methods that expose packed storage or decoded terms return owned values. A
builder can continue changing after `finish` without changing an earlier
snapshot. This rule prevents aliasing from invalidating rank directories,
sorted invariants, and canonical serialization.

## Query indexes

The bit vector stores 64-bit words, one absolute rank per 512-bit superblock,
and one relative rank per word. `rank1` is constant time. `select` binary
searches words by rank and scans at most one word. Higher-level structures use
that contract rather than maintaining duplicate prefix arrays.

Elias–Fano chooses `floor(log2(maximum / length))` low bits. The remaining high
values are represented as one bits at `high(value) + index`. Duplicates are
therefore preserved without special cases.

LOUDS stores each breadth-first node degree as `degree` one bits followed by a
zero terminator. Trie edge labels are in child-node order; terminal bits and
subtree term counts support exact and prefix queries.

Front coding stores a full restart term at each block boundary. Later records
store the common-prefix length and unmatched suffix. Random access decodes at
most one block.

## Validation boundaries

Builders validate logical input. Decoders first enforce byte/item/term limits,
then validate structural counts, canonical padding, topology closure,
monotonicity, sort order, restart alignment, and complete input consumption.
Derived indexes are rebuilt rather than trusted from serialized input.

## Extension rules

New structures should reuse `support`, `binary`, `packed`, and `bitvector`
where their invariants match. A feature belongs outside this repository when it
introduces mutable concurrent state, a database/storage engine, full-text
ranking, Roaring compatibility, a wavelet/FM index, or platform-specific I/O.
Those are consumers or neighboring projects, not reasons to blur this library's
static-index boundary.
