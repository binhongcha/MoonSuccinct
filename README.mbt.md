# MoonSuccinct

MoonSuccinct is an original, pure MoonBit library for immutable succinct index
primitives: rank/select bit vectors, Elias–Fano monotone sequences, LOUDS trees
and byte tries, and block front-coded dictionaries. It targets reusable index
layers in search, compilers, telemetry, storage metadata, static routing,
embedded catalogs, and WebAssembly applications.

Maintainer: `binhongcha`.
Source: [binhongcha/MoonSuccinct](https://github.com/binhongcha/MoonSuccinct).
Package: [binhongcha/moonsuccinct](https://mooncakes.io/docs/binhongcha/moonsuccinct).

October additions: cursor-based Elias–Fano seeking and skewed posting-list intersection; see [scope and complexity](docs/OCTOBER_FEATURES.md).

## Why this project

Many applications need fast queries over read-mostly identifiers, bitmaps,
trees, or sorted strings without adopting a complete search engine or database.
MoonSuccinct supplies those lower-level building blocks with a consistent
ownership model, typed failures, resource-bounded decoders, deterministic
formats, portable space reports, and tests on every MoonBit backend.

It deliberately does **not** duplicate a general BitSet, Roaring Bitmap,
wavelet/FM index, fuzzy matcher, full-text engine, database, or network service.
The detailed ecosystem collision analysis is in
[`docs/ECOSYSTEM_RESEARCH.md`](docs/ECOSYSTEM_RESEARCH.md).

## Features

- Packed immutable bit vector with `access`, `rank0/1`, `select0/1`, nearest
  zero/one navigation, range counts, and sparse position enumeration.
- Elias–Fano encoding for monotone non-decreasing `UInt64` sequences, including
  duplicates, checked indexed access, bounds, predecessor/successor, range
  slices, an append-only validator, and distinct intersection/union/difference.
- LOUDS rooted ordered topology with checked parent/child/degree navigation.
- Canonical static byte trie with exact lookup, lexicographic term numbers,
  prefix ranges, and bounded prefix enumeration.
- Block front-coded sorted byte dictionary with configurable restart interval,
  indexed access, exact lookup, lower bound, and bounded prefix enumeration.
- Versioned canonical binary formats, strict structural validation, explicit
  decode limits, stable error categories, and exact portable space accounting.
- No third-party runtime package dependency and no platform-specific core API.

## Packages

| Package | Purpose |
| --- | --- |
| `bitvector` | Packed bits, rank/select, navigation, codec, space report |
| `packed` | Internal fixed-width unsigned integer storage |
| `eliasfano` | Monotone integer index and set/range queries |
| `louds` | Rooted topology and static byte trie |
| `frontcoded` | Restart-block compressed sorted byte dictionary |
| `binary` | Bounded canonical reader and writer |
| `support` | Errors, limits, byte helpers, and space reports |
| `conformance` | Cross-structure embeddable smoke check and test suite |

## Install and use

Install the published package:

```text
moon add binhongcha/moonsuccinct@0.1.0
```

Import the required subpackages in your application's `moon.pkg`:

```moonbit nocheck
///|
import {
  "binhongcha/moonsuccinct/eliasfano",
  "binhongcha/moonsuccinct/louds",
  "binhongcha/moonsuccinct/frontcoded",
}
```

### Monotone posting list

```moonbit nocheck
let postings = @eliasfano.from_values([
  2UL, 5UL, 5UL, 21UL, 144UL, 1000UL,
])
assert_true(postings.contains(144UL))
assert_eq(postings.predecessor(500UL), Some(144UL))
assert_eq(postings.values_in_range(5UL, 1000UL, 10), [5UL, 5UL, 21UL, 144UL])
let restored = @eliasfano.decode(@eliasfano.encode(postings))
assert_eq(restored.to_values(), postings.to_values())
```

### Static prefix index

```moonbit nocheck
let terms : Array[Bytes] = [
  b"api/admin", b"api/catalog", b"api/catalog/items", b"docs",
]
let trie = @louds.trie_from_terms(terms)
assert_true(trie.contains(b"api/admin"))
assert_eq(
  trie.terms_with_prefix(b"api/catalog", 10),
  [b"api/catalog", b"api/catalog/items"],
)
```

### Front-coded symbol dictionary

```moonbit nocheck
let dictionary = @frontcoded.from_terms(
  [b"compile.module", b"compile.package", b"config.debug"],
  block_size=2,
)
assert_eq(dictionary.term_number(b"compile.package"), Some(1))
assert_eq(dictionary.terms_with_prefix(b"compile.", 10).length(), 2)
```

Every constructor and decoder above can raise `@support.SuccinctError`. Public
applications should propagate it or match its stable variants/codes.

## Runnable scenarios

```text
moon run examples/postings --target wasm-gc
moon run examples/taxonomy --target wasm-gc
moon run examples/dictionary --target wasm-gc
moon run examples/routing --target wasm-gc
```

The examples assert query and codec results before printing auditable space
figures. They represent an inverted list, an API route/taxonomy index, and a
compiler/configuration symbol dictionary. The routing example checks lexical
term selection and application-defined hierarchical byte-prefix matching.

## Quality gates

```text
moon fmt --check
moon check --target all --deny-warn --warn-list '-implicit_impl_as_method-test_unqualified_package'
moon test --target all --deny-warn --warn-list '-implicit_impl_as_method-test_unqualified_package'
moon build --target all --deny-warn --warn-list '-implicit_impl_as_method-test_unqualified_package'
python tools/count_moonbit.py --minimum 4001
```

CI runs the gates and all examples on Ubuntu, macOS, and Windows. The test suite
uses boundary tables, generated differential checks, codec corruption cases,
and cross-structure conformance checks on Wasm, Wasm-GC, JavaScript, and Native.
The scoped compiler migration baseline covers existing derived-method and
unqualified blackbox-test warnings; all other warnings remain fatal. This is
not a warning-free claim. See [release evidence](docs/RELEASE_0.1.0.md).

## Complexity and trade-offs

Bit-vector access/rank is `O(1)`; select is `O(log(words) + 64)`. Elias–Fano
bounds use binary search over indexed access. Trie lookup is proportional to
key length and sibling search. A front-coded random access decodes from the
nearest restart, so a larger block saves offset space but increases query work.
See [`docs/PERFORMANCE.md`](docs/PERFORMANCE.md) for exact accounting rules and
honest measurement guidance.

Static structures optimize repeated reads, deterministic transport, and compact
metadata. They are the wrong choice when updates dominate and rebuilding is
unacceptable.

## Binary safety and compatibility

Formats use magic bytes plus version 1, canonical varints, little-endian packed
words, exact record boundaries, and complete-input checks. Decoders rebuild
derived indexes and default to bounded input/item/term budgets. See
[`docs/BINARY_FORMATS.md`](docs/BINARY_FORMATS.md) and
[`docs/SECURITY.md`](docs/SECURITY.md).

## Project documentation

- [`CONTEXT.md`](CONTEXT.md): domain vocabulary and invariants
- [`docs/SPEC.md`](docs/SPEC.md): v0.1 requirements and non-goals
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md): package and ownership design
- [`docs/TESTING.md`](docs/TESTING.md): test oracles and quality gates
- [`docs/adr/0001-static-succinct-index-boundary.md`](docs/adr/0001-static-succinct-index-boundary.md): boundary decision
- [`THIRD_PARTY.md`](THIRD_PARTY.md): implementation provenance
- [`CHANGELOG.md`](CHANGELOG.md): release history

## License

Apache License 2.0. See [`LICENSE`](LICENSE). This repository contains no
unauthorized private, closed-source, commercial, or source-unknown code.

## 十月第二轮：Trie 词项反查与前缀匹配

`Trie::term_at(index)` 根据词项序号跳过子树并反查词项，越界返回 `None`。`longest_prefix_length(key)` 返回最长已存前缀的字节数，`prefix_lengths(key, max_matches?)` 返回全部已存前缀长度，最短在前并限制结果数。空词项匹配为 `Some(0)`，不是无匹配；任意二进制词项均可使用，应用自行定义路径分隔符边界。

前缀枚举改为显式 DFS 栈与单一路径，避免深词项递归和逐层路径复制；只复制返回词项。运行 `moon run examples/routing --target wasm-gc`。详见 [本轮审查与复杂度](docs/SECOND_REVIEW.md) 和 [十月申报资料稿](十月项目申报书.md)。
