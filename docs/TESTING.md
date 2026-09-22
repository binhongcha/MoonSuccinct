# Testing strategy

MoonSuccinct treats a plain logical representation as the test oracle. Compact
structures are useful only when they return exactly the same answers as simple
arrays and trees for every supported input.

## Test layers

1. **Example assertions** cover documented behavior and stable errors.
2. **Boundary tables** cover empty, minimum, maximum, all-zero, all-one,
   duplicate-heavy, dense, sparse, long-prefix, and invalid inputs.
3. **Deterministic generated cases** compare every query with a simple oracle.
4. **Codec corruption tests** truncate or alter every structural region and
   require a typed failure rather than a panic.
5. **Cross-target tests** run the same suite on Wasm, Wasm-GC, JavaScript, and
   Native.
6. **Executable examples** assert their own results and are run in CI.
7. **Benchmark workloads** verify answers before reporting measured work.

## Core oracles

- Rank scans the prefix and counts matching bits.
- Select scans until the requested occurrence is reached.
- Elias–Fano lookup is compared with a plain monotone `Array[UInt64]`.
- LOUDS navigation is compared with explicit parent and children arrays.
- Trie and dictionary results are compared with a sorted deduplicated array of
  `Bytes` terms and straightforward lexicographic scans.

## Required boundary cases

### Bit vectors

- lengths around every word, block, and superblock boundary;
- rank at position zero and exactly at length;
- select before/at/after the final occurrence;
- padding bits in the final packed word;
- long uniform runs and alternating bits.

### Elias–Fano

- empty and singleton sequences;
- repeated zero and repeated maximum values;
- dense ranges where the low-bit width is zero;
- large gaps and values near the accepted upper bound;
- one descending pair among otherwise valid input.

### LOUDS and trie

- root-only topology and one long chain;
- wide root, mixed branching, and invalid child totals;
- empty term, duplicate terms, embedded zero bytes, and 255-byte labels;
- absent prefix between two present terms;
- enumeration limit zero and limits smaller than the match count.

### Front coding

- block size one and blocks with a partial final block;
- identical long prefixes and no shared prefixes;
- binary terms containing zero and non-UTF-8 bytes;
- lookup at both sides of a restart term;
- malformed prefix lengths and oversized suffixes.

## Quality gates

The local acceptance command is:

```text
moon fmt --check
moon info
moon check --target all --deny-warn
moon test --target all --deny-warn
moon build --target all --deny-warn
```

Before release, CI must pass these commands on Ubuntu, macOS, and Windows. A
separate release check will re-run the ecosystem collision search and inspect
the generated public interfaces for accidental API growth.
