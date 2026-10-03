# MoonSuccinct

MoonSuccinct 是一个原创、纯 MoonBit 的静态紧凑索引基础库，提供 rank/select
位向量、Elias–Fano 单调整数序列、LOUDS 树与字节 Trie、分块前缀压缩字典。
它面向搜索索引、编译器符号表、遥测字段目录、存储元数据、静态路由、嵌入式
目录和 WebAssembly 应用等广泛的只读/读多写少场景。

维护账号：`binhongcha`。
源码：[binhongcha/MoonSuccinct](https://github.com/binhongcha/MoonSuccinct)。
包文档：[binhongcha/moonsuccinct](https://mooncakes.io/docs/binhongcha/moonsuccinct)。

十月新增 Elias–Fano 游标跳跃查找与偏斜倒排表交集，适用条件、复杂度及测试见 [October features](docs/OCTOBER_FEATURES.md)。

## 生态价值与边界

MoonSuccinct 解决的是“底层可复用静态索引部件”问题：调用方不必引入完整搜索
引擎或数据库，也能获得紧凑表示、可预测查询、稳定格式、资源受限解码和统一
错误语义。项目不实现通用 BitSet、Roaring Bitmap、wavelet/FM-index、模糊匹配、
全文检索、数据库或网络服务；结构表示、输入限制和业务边界见
[功能规格](docs/SPEC.md)。

## 核心能力

- 位向量：打包存储、`rank0/1`、`select0/1`、前后最近位、区间计数与稀疏位置枚举。
- Elias–Fano：支持重复值的非递减 `UInt64` 序列、随机访问、上下界、前驱后继、
  区间切片、增量校验构建器，以及去重交并差。
- LOUDS：有根有序树拓扑导航；静态字节 Trie 支持精确查询、词项序号、前缀范围
  与有界枚举。
- 前缀压缩字典：可配置 restart block，支持随机访问、lower bound、精确查询与
  前缀枚举。
- 稳定工程能力：版本化二进制格式、严格结构校验、显式解码额度、类型化错误、
  精确空间报告、四后端测试、三平台 CI。
- 核心库无第三方运行时包依赖，不使用平台特定 API。

安装：

```text
moon add binhongcha/moonsuccinct@0.1.0
```

在应用的 `moon.pkg` 中导入需要的子包，例如：

```moonbit
import {
  "binhongcha/moonsuccinct/eliasfano",
  "binhongcha/moonsuccinct/louds",
}
```

## 可运行示例

```text
moon run examples/postings --target wasm-gc
moon run examples/taxonomy --target wasm-gc
moon run examples/dictionary --target wasm-gc
moon run examples/routing --target wasm-gc
```

四个示例分别对应倒排表、分类树、符号字典和层级路由，先断言查询及格式
往返结果，再输出空间统计或验证结果。

## 本地验收

```text
moon fmt --check
moon check --target all --deny-warn --warn-list '-implicit_impl_as_method-test_unqualified_package'
moon test --target all --deny-warn --warn-list '-implicit_impl_as_method-test_unqualified_package'
moon build --target all --deny-warn --warn-list '-implicit_impl_as_method-test_unqualified_package'
python tools/count_moonbit.py --minimum 4001
```

CI 对 Ubuntu、macOS、Windows 执行相同门禁；测试覆盖 Wasm、Wasm-GC、
JavaScript、Native，包含边界表、确定性生成差分、损坏输入和跨结构一致性测试。
警告列表仅对既有派生方法、黑盒测试包名限定迁移设置基线，其余警告保持致命；
不声明完全无警告。发布证据见 [0.1.0 发布记录](docs/RELEASE_0.1.0.md)。

## 文档

Mooncakes 使用的完整英文包文档为 [`README.mbt.md`](README.mbt.md)。设计与验收
材料包括：

- [`CONTEXT.md`](CONTEXT.md)：领域术语与不变量
- [`docs/SPEC.md`](docs/SPEC.md)：v0.1 需求和非目标
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)：架构、依赖与所有权
- [`docs/BINARY_FORMATS.md`](docs/BINARY_FORMATS.md)：稳定二进制格式
- [`docs/SECURITY.md`](docs/SECURITY.md)：不可信输入与资源限制
- [`docs/PERFORMANCE.md`](docs/PERFORMANCE.md)：复杂度、空间口径和测量方法
- [`docs/TESTING.md`](docs/TESTING.md)：测试策略
- [`THIRD_PARTY.md`](THIRD_PARTY.md)：来源和第三方声明

## 许可证

Apache License 2.0。见 [`LICENSE`](LICENSE)。项目不包含未经授权的私有、闭源、
商业或来源不明代码。

## 十月第二轮：Trie 词项反查与前缀匹配

`Trie::term_at(index)` 根据词项序号跳过子树并反查词项，越界返回 `None`。`longest_prefix_length(key)` 返回最长已存前缀的字节数，`prefix_lengths(key, max_matches?)` 返回全部已存前缀长度，最短在前并限制结果数。空词项匹配为 `Some(0)`，不是无匹配；任意二进制词项均可使用，应用自行定义路径分隔符边界。

前缀枚举改为显式 DFS 栈与单一路径，避免深词项递归和逐层路径复制；只复制返回词项。运行 `moon run examples/routing --target wasm-gc`。详见 [功能与边界](docs/OCTOBER_FEATURES.md)。
