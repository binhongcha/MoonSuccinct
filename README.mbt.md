# MoonSuccinct

MoonSuccinct is an original, pure MoonBit library for static succinct index
primitives. It is being developed locally; no remote repository or Mooncakes
release has been created yet.

The planned v0.1 surface consists of a rank/select bit vector, Elias–Fano
monotone sequences, LOUDS tree and trie navigation, and a reusable front-coded
sorted dictionary. The project deliberately does not implement a general
BitSet, Roaring Bitmap, wavelet tree, FM-index, or full-text search engine.
