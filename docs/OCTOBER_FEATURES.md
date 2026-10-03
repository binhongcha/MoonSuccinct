# October additions: posting-list seeks

`EliasFano::lower_bound_from(start, target)` returns the first index at or after `start` whose value is at least `target`, or the sequence length. `start` must be in `[0, length]`; an invalid start raises `SuccinctError::OutOfRange`. Repeated values remain addressable. A nearby target costs O(log(d+1)) random accesses for advance distance `d`, versus O(log n) accesses for a global lower bound; each access still pays the Elias–Fano select cost.

`intersect_distinct_skewed(left, right)` returns a new immutable Elias–Fano sequence containing each common value once. It scans the shorter input and gallops through the longer one. It is intended for markedly unequal posting-list lengths. For similar lengths, the existing linear `intersect_distinct` may be faster and remains unchanged. The skewed algorithm has O(m log(n+1)) worst-case random accesses for short length `m` and long length `n`, plus O(k) output space for `k` matches.

Run `moon test eliasfano/galloping_search_test.mbt` and `moon test eliasfano/skewed_intersection_test.mbt`; the latter compares against the original merge result.

## 十月第二轮：Trie 词项反查与前缀匹配

`Trie::term_at(index)` 根据词项序号跳过子树并反查词项，越界返回 `None`。`longest_prefix_length(key)` 返回最长已存前缀的字节数，`prefix_lengths(key, max_matches?)` 返回全部已存前缀长度，最短在前并限制结果数。空词项匹配为 `Some(0)`，不是无匹配；任意二进制词项均可使用，应用自行定义路径分隔符边界。

前缀枚举改为显式 DFS 栈与单一路径，避免深词项递归和逐层路径复制；只复制返回词项。运行 `moon run examples/routing --target wasm-gc`。详见 [算法与复杂度](ARCHITECTURE.md)。
