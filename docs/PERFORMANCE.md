# Performance methodology

MoonSuccinct reports representation size exactly but does not claim universal
speed or compression superiority. Results depend on density, value universe,
prefix distribution, restart size, target backend, compiler version, and
runtime warm-up.

## Complexity summary

| Structure | Operation | Time | Additional query allocation |
| --- | --- | --- | --- |
| bit vector | access, rank | `O(1)` | none |
| bit vector | select | `O(log(words) + 64)` | none |
| bit vector | sparse positions | `O(k * select)` | `O(k)` result |
| Elias–Fano | indexed access | one select | none |
| Elias–Fano | bound/membership | `O(log n * select)` | none |
| Elias–Fano | distinct set merge | `O((n+m) * select)` | result |
| LOUDS | parent/degree/child | rank/select cost | small result arrays only where documented |
| byte trie | exact lookup | `O(length * log sibling_degree)` | none |
| front coding | indexed term | `O(block_size + term bytes)` | decoded term |
| front coding | lower bound | `O(log n * block decode)` | decoded terms |
| front coding | build sort/deduplicate | `O(n log n)` comparisons | copied input and result |

## Space reports

Every public structure exposes a `SpaceReport`. `payload_bits` counts canonical
encoded data; `auxiliary_bits` counts query metadata stored by MoonSuccinct;
`serialized_bytes` is the exact stable-format length. Runtime object headers,
allocator fragmentation, and temporary builder arrays are deliberately not
estimated. This separation prevents a portable report from pretending to be a
backend-specific heap profiler.

## Reproducible measurement

Record the MoonBit compiler version, target, optimization mode, CPU, operating
system, workload generator, item count, value distribution, and dictionary
block size. Verify every benchmark result against a plain-array oracle before
recording elapsed time. Run warm-up iterations for managed targets and report
multiple samples or a distribution rather than one favorable number.

The three examples print exact representation figures for small auditable
workloads. A larger benchmark should be added only when its timing source and
cross-platform reproducibility can be stated precisely; fabricated or
non-comparable throughput numbers are worse than no number.
