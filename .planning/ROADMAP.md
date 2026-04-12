# Roadmap: wellinformed v2.0

**Milestone:** v2.0 P2P Distributed Knowledge Graph
**Phases:** 15-18 (continues from v1.1 which ended at Phase 14)
**Requirements:** 30 mapped

## Phase 15: Peer Foundation + Security ✓ COMPLETE 2026-04-12

**Goal:** Peer identity, manual peer management, and secrets scanning so the security model is built BEFORE any sharing happens.

**Requirements:** PEER-01..05, SEC-01..06 (PEER-04 partial — live status deferred to Phase 18)

**Plans:** 4/4 complete

Plans:
- [x] 15-01-PLAN.md — Domain types + security scanner (peer.ts, sharing.ts, errors, config) — DONE 2026-04-12
- [x] 15-02-PLAN.md — Infrastructure layer (libp2p install, peer-transport.ts, peer-store.ts) — DONE 2026-04-12
- [x] 15-03-PLAN.md — CLI commands (peer add/remove/list/status, share audit, index.ts wiring) — DONE 2026-04-12
- [x] 15-04-PLAN.md — TDD test suite (37 tests, 11 requirements, 70/70 full suite pass) — DONE 2026-04-12

**Success criteria:**
1. First run generates ed25519 keypair at ~/.wellinformed/peer-identity.json
2. `peer add <multiaddr>` establishes a js-libp2p connection
3. Secrets scanner detects API keys in test fixtures and blocks them
4. `share audit --room X` shows the metadata that would be shared

## Phase 16: Room Sharing via Y.js CRDT ✓ COMPLETE 2026-04-12

**Goal:** Mark rooms as public, sync nodes across peers via Y.js. Metadata-only replication with incremental sync.

**Requirements:** SHARE-01..06 (live-network UAT deferred to Phase 17/18)

**Plans:** 4/4 complete

Plans:
- [x] 16-01-PLAN.md — Foundation: yjs+y-protocols install, ShareError, share-store, ydoc-store (V1 encoding, atomic writes) — DONE 2026-04-12
- [x] 16-02-PLAN.md — Sync engine: /wellinformed/share/1.0.0 libp2p protocol, REMOTE_ORIGIN echo prevention, secrets-scanned in/out updates, debounced graph flush — DONE 2026-04-12
- [x] 16-03-PLAN.md — CLI surface: `share room` (audit-gated), `unshare` (keeps .ydoc), daemon hook for runShareSyncTick — DONE 2026-04-12
- [x] 16-04-PLAN.md — TDD test suite: SHARE-01..06 + 5 pitfall regressions + local broadcast invariant (40 tests, 13 groups) — DONE 2026-04-12

**Success criteria:**
1. `share room homelab` makes a room available to connected peers
2. Peer B sees nodes from Peer A's shared room within 5 seconds
3. Concurrent node additions from both peers converge correctly
4. Offline peer reconnects and catches up without full resync

## Phase 17: Federated Search + Discovery ✓ COMPLETE 2026-04-12

**Goal:** Search across the P2P network. Tunnel detection across peers. Auto-discover peers on local network + DHT.

**Requirements:** FED-01..05, DISC-01..04 (DISC-04 coordination server explicitly deferred to Phase 18+; live-network UAT deferred to Phase 18)

**Plans:** 4/4 complete

Plans:
- [x] 17-01-PLAN.md — Foundation: 3 libp2p deps, SearchError 5-variant, PeerRecord.discovery_method, PeerConfig extensions — DONE 2026-04-12
- [x] 17-02-PLAN.md — Protocol + discovery infra: mDNS/DHT/peer:discovery, /wellinformed/search/1.0.0, token bucket, runFederatedSearch — DONE 2026-04-12
- [x] 17-03-PLAN.md — Surface: ask --peers, peer list column, 14th MCP tool federated_search, daemon search protocol — DONE 2026-04-12
- [x] 17-04-PLAN.md — TDD suite: 36 tests covering FED-01..05 + DISC-01..04 + 7 pitfalls (163/163 full suite pass) — DONE 2026-04-12

**Success criteria:**
1. `ask "query" --peers` returns results from connected peers' shared rooms
2. Results show which peer each result came from
3. mDNS discovers peers on the same local network automatically
4. MCP tool `federated_search` works from Claude Code

## Phase 18: Production Networking ✓ COMPLETE 2026-04-12

**Goal:** Production-grade P2P networking: multiplexed streams (yamux), NAT traversal (circuit-relay-v2 + dcutr + uPnPNAT), application-layer bandwidth management, and passive connection health monitoring. Last phase of v2.0 — after verify, the milestone ships.

**Requirements:** NET-01..04 (all complete)

**Plans:** 4/4 complete

Plans:
- [x] 18-01-PLAN.md — Foundation: 3 libp2p deps (circuit-relay-v2@4.2.0 + dcutr@3.0.15 + upnp-nat@4.0.15 + identify@4.1.0 transitive), NetError 6-variant, PeerConfig.relays/upnp/bandwidth — DONE 2026-04-12
- [x] 18-02-PLAN.md — Infrastructure: bandwidth-limiter.ts (Semaphore + re-exported createRateLimiter), connection-health.ts (in-memory HealthTracker), peer-transport wiring (circuitRelayTransport + dcutr + uPnPNAT) — DONE 2026-04-12
- [x] 18-03-PLAN.md — Integration: share-sync bandwidth gate with BandwidthExceeded error, daemon connection:close listener + conn.limits filter + relay pre-dial, peer list health column — DONE 2026-04-12
- [x] 18-04-PLAN.md — TDD suite: 685 lines, 44 tests across 3 tiers (structural + unit + 10-peer integration in ~2.5s), all 7 pitfalls regression-locked (243/243 full suite pass) — DONE 2026-04-12

**Success criteria:**
1. Peers behind NAT connect via libp2p relay + hole punching
2. Sync rate is configurable and does not flood bandwidth
3. Connection drops are detected and auto-reconnected
4. 10+ peers connected simultaneously without degradation

## Phase 19: Structured Codebase Indexing ✓ COMPLETE 2026-04-12

**Goal:** Parse codebases into a rich, structured code graph (classes, functions, signatures, call graph) stored separately from the research room graph. Codebases are first-class aggregates attachable to rooms via a join table. Powered by tree-sitter with TypeScript + Python grammars.

**Requirements:** CODE-01..08 (all 8 complete)

**Plans:** 4/4 complete

Plans:
- [x] 19-01-PLAN.md — Foundation: tree-sitter@0.21.1 + typescript@0.23.2 + python@0.23.4 (exact pins), CodebaseError (8 variants), src/domain/codebase.ts (163 lines), src/infrastructure/code-graph.ts (429 lines, 11 repo methods) — DONE 2026-04-12
- [x] 19-02-PLAN.md — Parser + indexer: tree-sitter-parser.ts (384 lines, Map<Lang,Parser> cache, CJS interop), codebase-indexer.ts (350 lines, two-pass exact/heuristic/unresolved resolution, content-hash incremental) — DONE 2026-04-12
- [x] 19-03-PLAN.md — CLI + MCP: cli/commands/codebase.ts (430 lines, 8 subcommands), runtime.ts (codeGraph path), cli/index.ts (dispatcher), mcp/server.ts (15th tool code_graph_query) — DONE 2026-04-12
- [x] 19-04-PLAN.md — TDD suite: 5 fixtures + tests/phase19.codebase-indexing.test.ts (757 lines, 14 describe groups, 36 tests, 199/199 full suite pass) — DONE 2026-04-12

**Success criteria:**
1. `wellinformed codebase index <path>` parses a TypeScript/JavaScript codebase into `~/.wellinformed/code-graph.db` with classes, functions, methods, imports, exports
2. `wellinformed codebase attach <codebase-id> --room <room-id>` attaches a codebase to a research room (M:N)
3. `wellinformed codebase search <query>` returns code nodes by semantic match across attached codebases
4. New MCP tool `code_graph_query` lets Claude query the structured code graph independently of research rooms

## Phase Summary

| Phase | Name | Requirements | Success Criteria |
|-------|------|-------------|------------------|
| 15 | Peer Foundation + Security | PEER-01..05, SEC-01..06 (11) | 4 |
| 16 | Room Sharing (Y.js CRDT) | SHARE-01..06 (6) | 4 |
| 17 | Federated Search + Discovery | FED-01..05, DISC-01..04 (9) | 4 |
| 18 | Production Networking | NET-01..04 (4) | 4 |
| 19 | Structured Codebase Indexing | CODE-01..08 (8) | 4 |
| **Total** | | **38** | **20** |

---
*Roadmap created: 2026-04-12 (Phase 19 added 2026-04-12 after Phase 18 kickoff)*
