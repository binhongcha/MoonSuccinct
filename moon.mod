// Learn more about moon.mod configuration:
// https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html
//
// To add a dependency, run this command in your terminal:
//   moon add moonbitlang/x
//
// Or manually declare it in `import`, for example:
// import {
//   "moonbitlang/x@0.4.6",
// }

name = "binhongcha/moonsuccinct"

version = "0.1.0"

readme = "README.mbt.md"

repository = "https://github.com/binhongcha/MoonSuccinct"

license = "Apache-2.0"

keywords = [
  "succinct",
  "rank-select",
  "elias-fano",
  "louds",
  "compressed-index",
]

preferred_target = "wasm-gc"

description = "Static succinct index primitives for MoonBit"
