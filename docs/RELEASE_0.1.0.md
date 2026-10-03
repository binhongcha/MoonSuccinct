# MoonSuccinct 0.1.0 发布记录

日期：2026-10-03；维护账号：`binhongcha`。

## 发布配置与历史

- 公开仓库：https://github.com/binhongcha/MoonSuccinct
- 包名：`binhongcha/moonsuccinct@0.1.0`；默认分支：`main`；Apache-2.0。
- 原 50 条未推送提交先完整 bundle 备份并校验，再统一作者及提交者身份。旧申报材料中的个人字段在发布前脱敏；只有申报文档历史内容改变，代码、提交消息、日期与开发顺序保留。
- 原始 bundle 与原始到发布历史的提交映射保存在仓库外的本地备份中，不推送、不打包。
- 模块、内部导入、公开接口与 README 同步使用 `binhongcha`；没有改动索引算法或二进制格式。
- 有效 MoonBit 总计 4,739 行，非测试含示例/自检 3,087 行，其余为测试；不声明库实现超过 4k。计数工具排除构建、依赖缓存和 Git 目录。

## 本地验证

- 工具链：`moon 0.1.20260827`、`moonc v0.10.14+7d59c7ec9`。
- Wasm、Wasm-GC、JS、Native 全部检查、构建与完整测试通过，每后端 99/99。
- `cmd/main` 自检、postings/taxonomy/dictionary/routing 四个 Wasm-GC 示例执行通过。
- 格式检查、公开接口生成、包文档生成与 `python tools/count_moonbit.py --minimum 4001` 通过。
- 与 CI 一致的定向编译器迁移警告基线为 `-implicit_impl_as_method-test_unqualified_package`；其余警告保持致命，不宣称完全无警告。
- 发布源码：`dcb1ad553d813d430436bd92d06fc0978bed8cd3`。
- 发布源 CI：[37114206550](https://github.com/binhongcha/MoonSuccinct/actions/runs/37114206550)，Ubuntu/macOS/Windows 与公开接口/文档作业全部成功。
- Mooncakes 发布：打包与解包检查通过，服务端 `200 OK`；[公开包文档](https://mooncakes.io/docs/binhongcha/moonsuccinct) HTTP 200。
- 发布 ZIP SHA-256：`f996adb9a2d92eaf8cd3f2fc01ce76f7e250af23f2dcd38eafb69e4715e925f9`；136 个条目，无私有 Git、构建/依赖缓存或本地备份目录，申报存档无邮箱/手机号匹配。
- 独立消费者通过 `moon add binhongcha/moonsuccinct@0.1.0` 从公共注册表下载，无本地路径依赖；检查与 Wasm-GC 运行通过，验证版本、rank/select、Elias–Fano 游标/交集、编码往返、Trie 词项/前缀与前缀压缩字典查询，并拒绝损坏输入。
- GitHub Release：[v0.1.0](https://github.com/binhongcha/MoonSuccinct/releases/tag/v0.1.0)，非草稿；发布者与 annotated tag 的 tagger 均为 `binhongcha`，标签精确指向发布源码。
- 发布后的 main 仅补录三份文档，不覆盖或重发 0.1.0；最新 CI 见 [Actions](https://github.com/binhongcha/MoonSuccinct/actions)。

## 功能与申报边界

结构面向静态构建与重复查询，更新需要重建；前缀匹配按字节计数，路径分隔符语义由应用提供。此库不是全文搜索引擎、数据库或动态索引。

申报资料的参赛者与联系方式保持空白，由申请人按十月章程核实并人工定稿。本记录不是赛事组正式验收结论。
