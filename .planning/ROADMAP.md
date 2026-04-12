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

## Phase 17: Federated Search + Discovery

**Goal:** Search across the P2P network. Tunnel detection across peers. Auto-discover peers on local network + DHT.

**Requirements:** FED-01..05, DISC-01..04 (DISC-04 coordination server explicitly deferred to Phase 18+)

**Plans:** 4 plans

Plans:
- [ ] 17-01-PLAN.md — Foundation: install @libp2p/mdns + kad-dht + bootstrap (exact pins), add SearchError 5-variant union to AppError/formatError, PeerRecord.discovery_method optional, PeerConfig.mdns/dht/search_rate_limit (Wave 1)
- [ ] 17-02-PLAN.md — Protocol + discovery infra: peer-transport.ts mDNS/DHT/identify wiring with peer:discovery→dial+persist, /wellinformed/search/1.0.0 handler, token bucket rate limiter, runFederatedSearch orchestrator with parallel fan-out + 2s timeout + findTunnels pass (Wave 2)
- [ ] 17-03-PLAN.md — Surface: `ask --peers` flag + askFederated helper, peer list discovery_method column, MCP 14th tool `federated_search` with privacy disclosure, daemon bootstrap registers search protocol alongside share protocol (Wave 3)
- [ ] 17-04-PLAN.md — TDD test suite: 3 files (federated-search + mcp-tool + discovery) covering FED-01..05 + DISC-01..04 + all 7 pitfalls from research (mDNS auto-dial, Docker/WSL mDNS, Float32 precision, DHT+identify, SearchError exhaustive, PeerRecord migration, rate limiter leak) (Wave 4)

**Success criteria:**
1. `ask "query" --peers` returns results from connected peers' shared rooms
2. Results show which peer each result came from
3. mDNS discovers peers on the same local network automatically
4. MCP tool `federated_search` works from Claude Code

## Phase 18: Production Networking

**Goal:** Production-grade P2P networking: multiplexed streams, NAT traversal, bandwidth management, auto-reconnect.

**Requirements:** NET-01..04

**Success criteria:**
1. Peers behind NAT connect via libp2p relay + hole punching
2. Sync rate is configurable and doesn't flood bandwidth
3. Connection drops are detected and auto-reconnected
4. 10+ peers connected simultaneously without degradation

## Phase Summary

| Phase | Name | Requirements | Success Criteria |
|-------|------|-------------|------------------|
| 15 | Peer Foundation + Security | PEER-01..05, SEC-01..06 (11) | 4 |
| 16 | Room Sharing (Y.js CRDT) | SHARE-01..06 (6) | 4 |
| 17 | Federated Search + Discovery | FED-01..05, DISC-01..04 (9) | 4 |
| 18 | Production Networking | NET-01..04 (4) | 4 |
| **Total** | | **30** | **16** |

---
*Roadmap created: 2026-04-12*
