# MoonSuccinct v0.1 specification

## Product boundary

MoonSuccinct is a pure MoonBit library for immutable succinct index primitives.
Every structure is built from caller-owned logical values, validates its input,
owns its encoded representation, and provides a deterministic space report.
The portable core must check and test on Wasm, Wasm-GC, JavaScript, and Native.

## Functional requirements

### Packed bits and rank/select

1. A builder accepts zero or one bits and can append repeated bits.
2. A frozen bit vector exposes length, access, one/zero count, and packed words.
3. `rank1(i)` and `rank0(i)` count a half-open prefix `[0, i)` and accept
   `0 <= i <= length`.
4. `select1(k)` and `select0(k)` use zero-based occurrence numbers and return
   `None` when `k` is outside the represented population.
5. The query index uses superblocks and blocks rather than a full prefix-count
   array per bit.

### Elias–Fano monotone sequences

1. Input values are non-negative and monotone non-decreasing; duplicates are
   preserved.
2. The representation splits every value into low bits and unary-coded high
   positions backed by rank/select.
3. Queries include length, indexed get, lower/upper bound, contains,
   predecessor, successor, minimum, and maximum.
4. Empty, singleton, all-equal, dense, sparse, and duplicate-heavy sequences
   have defined behavior.

### LOUDS topology and trie

1. A topology builder accepts node degrees in breadth-first order and rejects
   impossible degree sequences.
2. Navigation includes root, parent, degree, first child, child by offset,
   children, and leaf detection.
3. A trie builder accepts arbitrary byte terms, sorts and deduplicates them,
   and freezes a LOUDS topology plus edge labels and terminal bits.
4. Trie queries include exact membership, node lookup, prefix range, and
   bounded lexicographic prefix enumeration.

### Front-coded dictionary

1. Input byte terms are sorted and deduplicated by the builder.
2. Each block stores one restart term followed by common-prefix/suffix records.
3. Queries include indexed get, exact lookup, lower bound, prefix range, and
   bounded prefix enumeration.
4. Block size is configurable and validated.

### Stable binary formats

1. Each public structure has a versioned format with magic bytes and explicit
   length fields.
2. Decoders reject truncation, overflow, inconsistent counts, invalid padding,
   non-monotone reconstructed values, and trailing bytes.
3. A successful decode preserves the logical sequence and query behavior.
4. The format is deterministic across supported targets.

### Measurement and examples

1. Every structure reports logical item counts, encoded data bits, auxiliary
   index bits, total bytes, and relevant configuration.
2. Benchmarks compare results with a plain reference representation and report
   measured construction/query work without claiming universal superiority.
3. Runnable examples cover posting lists, a static route/taxonomy trie, and a
   front-coded command or symbol dictionary.

## Complexity targets

| Structure | Operation | Target |
| --- | --- | --- |
| Rank/select bit vector | access/rank | O(1) |
| Rank/select bit vector | select | O(log blocks + word scan) or better |
| Elias–Fano | indexed get | O(1) over select |
| Elias–Fano | lower bound | O(log n) |
| LOUDS topology | parent/degree/child | O(rank/select cost) |
| LOUDS trie | exact lookup | O(m log d) or better for term length m |
| Front-coded dictionary | indexed get | O(block size + term length) |
| Front-coded dictionary | lower bound | O(log blocks + block size) |

## Resource and correctness rules

- Public constructors return typed errors for invalid caller input.
- Decoders accept explicit byte, item, and nesting limits where allocation is
  driven by untrusted encoded lengths.
- No query may panic for an empty structure or an out-of-range public input.
- Size arithmetic is checked before allocating or indexing.
- Documentation distinguishes logical size, encoded payload, auxiliary index,
  object/runtime overhead, and serialized size.

## Explicit non-goals

- Mutable succinct structures or concurrent mutation.
- General-purpose BitSet operations.
- Roaring Bitmap compatibility.
- Wavelet trees/matrices, BWT, FM-index, or full-text ranking.
- Persistence engine, memory mapping, database, or network service.
- Claims of information-theoretic optimality without a proved bound.
