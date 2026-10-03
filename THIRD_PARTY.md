# Third-party and provenance statement

MoonSuccinct is an original implementation. Its MoonBit source does not copy or
translate third-party source code and has no runtime package dependency outside
the MoonBit standard library/toolchain.

The design uses published data-structure concepts: rank/select bit vectors,
Elias–Fano monotone sequences, LOUDS tree encoding, and block front coding.
Those concepts are widely documented and are not treated as vendored code.

Design comparison references are [SDSL](https://github.com/simongog/sdsl-lite),
[the Rust sux Elias–Fano API](https://docs.rs/sux/latest/sux/dict/elias_fano/struct.EliasFano.html),
and [the Rust louds API](https://docs.rs/louds/latest/louds/). These were used only
as evidence that the problem category is mature and useful. No source, tests,
documentation text, or binary asset from those projects is included.

Repository automation uses GitHub Actions maintained by GitHub and the
community MoonBit setup action. Their code executes in CI and is not
redistributed as part of the Mooncakes package.
