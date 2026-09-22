# Security and robustness

MoonSuccinct accepts arbitrary logical values in builders and potentially
untrusted bytes in decoders. It does not perform file, network, process, or
unsafe-memory operations.

## Decoder limits

`DecodeLimits::sensible()` defaults to 64 MiB input, 10 million items, 1 MiB
per term, and 64 MiB cumulative term bytes. Applications with smaller records
should lower these limits. Raising them increases memory and CPU exposure and
must be based on an application-level trust and quota decision.

Lengths are checked before allocation or traversal. Decoders reject truncated
varints, overflow, inconsistent word/count fields, nonzero padding, invalid
tree closure, unsorted labels or terms, impossible prefix lengths, misplaced
restart offsets, unsupported versions, and trailing bytes. They rebuild rank
and subtree indexes rather than accepting attacker-supplied derived metadata.

## Complexity exposure

Valid but adversarial data can still consume work up to configured limits.
Front-coded lookup reconstructs at most a restart block; large block sizes save
offset space at the cost of more decoding. Trie prefix enumeration is bounded
by an explicit result limit. Callers should avoid materializing all matches
from an untrusted empty prefix.

Construction currently holds logical input and the immutable output in memory.
The incremental Elias–Fano builder validates values as they arrive, but the
final bit split still requires the count and maximum. It is not a disk-backed
or constant-memory ingestion system.

## Integrity and authenticity

Canonical format validation detects malformed structure, not malicious
replacement. Applications needing provenance must authenticate the serialized
bytes with a signature, MAC, trusted digest, or protected transport outside
MoonSuccinct.

## Reporting

Until a public repository is created, report suspected vulnerabilities
privately to the maintainer through the contest contact channel. Do not include
private datasets or credentials. After publication, the repository security
policy will identify the preferred private advisory route.
