# Keep v0.1 static and representation-focused

MoonSuccinct v0.1 will provide rank/select bit vectors, Elias–Fano monotone
sequences, LOUDS topology and trie navigation, and a front-coded sorted
dictionary as immutable index primitives. We rejected a dynamic collection,
Roaring-compatible integer set, wavelet tree, FM-index, and complete search
engine because those choices either duplicate current MoonBit projects or hide
the representation guarantees behind a much larger product boundary.

The shared seam is a static logical sequence plus measurable auxiliary index
bits. Builders may be mutable while assembling input, but every published
query object is immutable. Future dynamic structures must use a separate type
and format rather than weakening this contract.
