# October additions: posting-list seeks

`EliasFano::lower_bound_from(start, target)` returns the first index at or after `start` whose value is at least `target`, or the sequence length. `start` must be in `[0, length]`; an invalid start raises `SuccinctError::OutOfRange`. Repeated values remain addressable. A nearby target costs O(log(d+1)) random accesses for advance distance `d`, versus O(log n) accesses for a global lower bound; each access still pays the Elias–Fano select cost.

`intersect_distinct_skewed(left, right)` returns a new immutable Elias–Fano sequence containing each common value once. It scans the shorter input and gallops through the longer one. It is intended for markedly unequal posting-list lengths. For similar lengths, the existing linear `intersect_distinct` may be faster and remains unchanged. The skewed algorithm has O(m log(n+1)) worst-case random accesses for short length `m` and long length `n`, plus O(k) output space for `k` matches.

Run `moon test eliasfano/galloping_search_test.mbt` and `moon test eliasfano/skewed_intersection_test.mbt`; the latter compares against the original merge result.
