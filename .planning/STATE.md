---
gsd_state_version: 1.0
milestone: v2.0
milestone_name: milestone
status: unknown
last_updated: "2026-04-13T13:39:25.750Z"
progress:
  total_phases: 6
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
---

# State

## Current Position

Phase: 20 (Session Persistence) — EXECUTING
Plan: 3 of 4

### Plan 20-02 Complete (2026-04-13T14:00:00Z)

- Commits: f8f937c, 20eb582, e1c88d3
- Files: src/infrastructure/sessions-state.ts (new — atomic tmp+rename state I/O), src/infrastructure/sources/claude-sessions.ts (new — source adapter), src/domain/sources.ts (claude_sessions added to SourceKind), src/infrastructure/sources/registry.ts (claudeSessionsSource + ClaudeSessionsDeps), src/cli/runtime.ts (claudeSessions deps wired), tests/phase{2,3,4,5,6}.*.test.ts (stub deps added)
- Summary: .planning/phases/phase-20/20-02-SUMMARY.md
- Delivers SESS-01, SESS-02, SESS-03
- 243/243 tests pass, npx tsc --noEmit exits 0, 0 new npm packages
- Decision: scanNode applied to baseSummary directly AND canonical GraphNode fields — double-check ensures user messages with pasted API keys are caught
- Decision: mutateSessionsState called once per tick (not per file) — accumulate updates map, single lock+write cycle for N files

### Plan 20-01 Complete (2026-04-13T12:55:42Z)

- Commits: 5e6d77e, dd06820, b797957
- Files: src/domain/errors.ts (SessionError 5 variants), src/domain/sessions.ts (new), src/infrastructure/config-loader.ts (SessionsConfig), src/infrastructure/share-store.ts (shareable flag), src/cli/commands/share.ts (shareable: true fix)
- Summary: .planning/phases/phase-20/20-01-SUMMARY.md

### Plan 19-01 Complete (2026-04-12T14:13:00Z)

- Commits: 9284632, 1eb5e2e, b50c430
- Files: package.json (tree-sitter@0.21.1, tree-sitter-typescript@0.23.2, tree-sitter-python@0.23.4), src/domain/errors.ts (CodebaseError 8 variants), src/domain/codebase.ts (new), src/infrastructure/code-graph.ts (new)
- Summary: .planning/phases/phase-19/19-01-SUMMARY.md
- Delivers CODE-01, CODE-02, CODE-03, CODE-04 (foundation types + persistence layer)
- 163/163 tests pass, scope boundaries verified (sources/codebase.ts + index-project.ts untouched)
- Decision: tree-sitter@0.21.1 used (plan's 0.25.0 incompatible with typescript grammar peer deps)

### Plan 17-02 Complete (2026-04-12T12:50:42Z)

- Commits: 2a8f4ba, 83876eb, 29a45a9
- Files: src/infrastructure/peer-transport.ts (mDNS/DHT/peer:discovery), src/infrastructure/search-sync.ts (new — 508 lines), src/application/federated-search.ts (new — 294 lines)
- Summary: .planning/phases/phase-17/17-02-SUMMARY.md
- Delivers DISC-02/03 (mDNS default on, DHT wired off), FED-02/03/04 (protocol handler + fan-out + tunnel pass)
- 127/127 tests pass, all 7 pitfall patterns grep-verified

### Plan 17-01 Complete (2026-04-12T12:41:00Z)

- Commits: 94db382, 7675409
- Files: package.json, src/domain/errors.ts, src/infrastructure/peer-store.ts, src/infrastructure/config-loader.ts
- Summary: .planning/phases/phase-17/17-01-SUMMARY.md

### Plan 16-04 Complete (2026-04-12T11:30:00Z)

- Commits: fa9ef10
- Files: tests/phase16.share-crdt.test.ts (new — 969 lines, 40 tests, 13 describe groups)
- Summary: .planning/phases/phase-16/16-04-SUMMARY.md
- Result: npm test 127/127 pass (87 prior + 40 new), 0 regressions
- Covers SHARE-01..06 + 5 pitfall regressions (echo loop, V1/V2, empty-response guard, init order, Uint8ArrayList pipeline)

### Plan 16-03 Complete (2026-04-12T11:04:47Z)

- Commits: 8e2807f, 95dba6f, 9b1e12e
- Files: src/cli/commands/share.ts (extended — room subcommand), src/cli/commands/unshare.ts (new), src/cli/index.ts (unshare registered), src/daemon/loop.ts (shareSync hook + libp2p bootstrap)
- Summary: .planning/phases/phase-16/16-03-SUMMARY.md
- Delivers SHARE-01 (audit gate), SHARE-02 (unshare), SHARE-03/05/06 (daemon tick), SHARE-04 (Y.Doc seeding)

### Plan 16-01 Complete (2026-04-12T10:24:51Z)

- Commits: 92e9aa6, a47648e, 8054e55, 730a081
- Files: package.json (yjs@13.6.30 + y-protocols@1.0.7), src/domain/errors.ts (ShareError 7 variants), src/infrastructure/share-store.ts (new), src/infrastructure/ydoc-store.ts (new)
- Summary: .planning/phases/phase-16/16-01-SUMMARY.md

### Plan 15-01 Complete (2026-04-12T07:58:38Z)

- Commits: 49f02c2, b3b6c95
- Files: src/domain/peer.ts (new), src/domain/sharing.ts (new), src/domain/errors.ts (extended), src/infrastructure/config-loader.ts (extended)
- Summary: .planning/phases/phase-15/15-01-SUMMARY.md

### Plan 15-02 Complete (2026-04-12T08:11:00Z)

- Commits: 49c6968, 841b212
- Files: src/infrastructure/peer-transport.ts (new), src/infrastructure/peer-store.ts (new), package.json (4 new libp2p deps)
- Summary: .planning/phases/phase-15/15-02-SUMMARY.md

### Plan 15-03 Complete (2026-04-12T11:17:00Z)

- Commits: ba7db60, 15394ef
- Files: src/cli/commands/peer.ts (new), src/cli/commands/share.ts (new), src/cli/index.ts (modified)
- Summary: .planning/phases/phase-15/15-03-SUMMARY.md
- Delivers PEER-02/03/05 + SEC-04 fully; PEER-04 partial (live status deferred to Phase 18)

## Project Reference

See: .planning/PROJECT.md (updated 2026-04-12)

**Core value:** Your coding agent answers from your actual research and codebase, not its training data.
**Current focus:** Phase 18 — Production Networking

## Accumulated Context

- Y.js (21.6K stars) for CRDT, js-libp2p (2.5K) for networking
- 96.8% NDCG@10, 100% R@5 on BEIR benchmark — proven IR quality
- 23 source adapters, 13 MCP tools, 499 nodes in production graph
- sequenceLazy thunks for sequential ResultAsync (never eager map)
- Functional DDD: no classes in domain/app, neverthrow Results
- PreToolUse hook is the key differentiator for agent integration
- ShareableNode excludes file_type/source_file at type level (SEC-03)
- PeerError has 10 variants; PeerStoreReadError/WriteError separate from identity errors
- ScanError SecretDetected is hard-block, no override (SEC-02)
- 10 built-in secret patterns, extensible via SecurityConfig.secrets_patterns

## Accumulated Context

- libp2p 3.x API: `privateKeyFromRaw` (not `unmarshalEd25519PrivateKey`) for ed25519 deserialization
- `dirname()` preferred over regex for parent dir extraction in node:path
- Transitive deps (@libp2p/crypto/keys, @libp2p/peer-id, @multiformats/multiaddr) importable without explicit package.json entry
- Atomic peers.json: writeFile(tmp) + rename(tmp, path) — POSIX atomic, no partial reads

## Decisions

- PeerStoreReadError + PeerStoreWriteError kept separate from PeerIdentityRead/WriteError (peers.json ≠ peer-identity.json)
- ShareableNode enforces SEC-03 boundary at the type system level, not runtime filtering
- AppError union now covers all 6 bounded contexts: GraphError | VectorError | EmbeddingError | PeerError | ScanError | ShareError
- privateKeyFromRaw (libp2p 3.x) replaces plan's unmarshalEd25519PrivateKey (old API no longer exported)
- PE.transportError used for hangUpPeer failures (PE.notFound reserved for registry lookup misses only)
- [Phase 15]: All 37 Phase 15 tests went GREEN on first run — implementations from Plans 01+02 were already correct
- [Plan 15-03]: `node.stop()` placed in try/finally of `peer add` — guarantees libp2p cleanup on every exit path
- [Plan 15-03]: `peer list` reads peers.json only; live connection status, latency, shared rooms deferred to Phase 18 NET layer
- [Plan 15-03]: `peer status` displays public key via `identity.privateKey.raw.slice(32)` — second 32 bytes of ed25519 raw form, no extra libp2p round-trip
- [Plan 15-03]: `share audit` uses fileGraphRepository directly — avoids opening sqlite vector index for read-only audit
- [Plan 15-03]: formatError accepts GraphError/PeerError/ScanError without casts — all are AppError union members
- [Plan 15-03]: `share audit --json` emits full ShareableNode records + ScanMatch arrays (not just counts)
- [Plan 16-01]: yjs@13.6.30 + y-protocols@1.0.7 pinned exact (no ^ or ~); dep budget = 2 new direct deps
- [Plan 16-01]: V1 encoding enforced in ydoc-store.ts — encodeStateAsUpdate/applyUpdate only; V2 APIs explicitly forbidden
- [Plan 16-01]: Per-path writeQueues Map serializes concurrent saveYDoc calls; snapshot taken synchronously at call time
- [Plan 16-01]: loadYDoc never calls doc.getMap — strict init order (new Doc → applyUpdate → return to caller)
- [Phase phase-16]: Used it-length-prefixed lp.encode/lp.decode directly on libp2p Stream's AsyncIterable instead of missing it-length-prefixed-stream transitive dep
- [Plan 16-04]: Block-comment stripping applied before doesNotMatch structural assertions — JSDoc mentions of forbidden APIs do not cause false failures
- [Plan 16-04]: Uint8ArrayList.subarray structural test uses pipeline pattern (frameIter .subarray() + handleInboundFrame param type) — flatten-in-iterator design, not co-located with createDecoder
- [Plan 16-04]: Phase 16 complete — 127/127 tests pass, all SHARE-01..06 requirements locked by regression tests
- [Phase phase-17]: @libp2p/identify not installed — not available transitively from libp2p@3.2.0 or new deps, and not required by any Phase 17 code
- [Phase phase-17]: PEERS_FILE_VERSION stays at 1 — discovery_method is additive-optional; no migration needed
- [Phase phase-17]: SearchError is 7th bounded context in AppError; formatError has exhaustive switch for all 5 variants; mdns default true (DISC-02), dht.enabled default false (DISC-03), search_rate_limit 10/30 locked
- [Phase phase-17]: DISC-04 coordination server explicitly deferred — @libp2p/bootstrap installed for DHT seed peer list only
- [Plan 17-02]: FramedStream copied from share-sync.ts (NOT imported) — search and share stream lifecycles are independent per CONTEXT.md
- [Plan 17-02]: Fan-out uses Promise.all + Promise.race(2s) per peer — NOT ResultAsync.combine (short-circuits on first error)
- [Plan 17-02]: DHT runs clientMode:true without @libp2p/identify — package not available transitively; clientMode routing is passive
- [Plan 17-02]: Peer-only rows skipped in tunnel pass — raw vectors not transmitted on wire (SEC-03 boundary); documented functional subset
- [Phase phase-17]: Short-lived libp2p node per ask --peers / federated_search invocation
- [Phase phase-19]: createRequire(import.meta.url) for ESM→CJS tree-sitter interop
- [Phase phase-19]: Two-pass call graph resolution: PendingCall[] in pass 1, nameToNodes map resolution in pass 2
- [Phase phase-19]: codebase CLI uses Record key-lookup dispatch (not switch) matching existing peer/share/unshare pattern
- [Phase phase-19]: tree-sitter version pins corrected to 0.21.1/0.23.2/0.23.4 in test assertions (plan spec was stale 0.25.0)
- [Phase phase-18]: ESM-only libp2p v3 packages require import() not require(); verified via dynamic import
- [Phase phase-18]: NetError formatError cases appended after CodebaseInvalidPathError without default clause for TypeScript exhaustiveness
- [Phase phase-18]: autoConfirmAddress:true on uPnPNAT bypasses @libp2p/autonat dependency without additional install
- [Phase phase-18]: @libp2p/identify@4.1.0 added — circuitRelayTransport RelayDiscovery unconditionally requires it
- [Phase phase-18]: health: 'unknown' in CLI; live health deferred to Phase 19+ daemon IPC/MCP
- [Phase phase-18]: Bandwidth gate runs before secrets scan; burst=rate for share limiter
- [Phase phase-18]: Relay pre-dial best-effort: failures logged but daemon never crashes
- [Phase phase-18]: bandwidth gate returns errAsync(BandwidthExceeded) — write rejected, not silently accepted
- [Phase phase-18]: 10-peer integration test completes in ~2.5s with ring+cross-link mesh (listenPort:0, mdns:false, Promise.allSettled)
- [Phase phase-20]: SessionEntryKind uses session_start_hook (not attachment) to reflect semantic role, not JSONL structural type
- [Phase phase-20]: shareable defaults to true for legacy v1 SharedRoomRecord on read; sessions room will be created with shareable: false in Plan 03
- [Phase phase-20]: scanNode applied to both baseSummary directly and canonical GraphNode fields — double-check ensures user messages with pasted API keys are caught even though canonical scanNode only covers ShareableNode fields
- [Phase phase-20]: mutateSessionsState called once per tick (not per file) — accumulate updates map, single lock+write cycle for N files
- [Phase phase20]: rollupSessions exported from CLI module and imported dynamically by MCP tool to avoid circular deps
- [Phase phase20]: shell hook branches on CLAUDE_HOOK_EVENT — single script, two modes (SessionStart + PreToolUse)
