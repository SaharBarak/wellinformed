# Phase 16: Room Sharing via Y.js CRDT - Context

**Gathered:** 2026-04-12
**Status:** Ready for planning

<domain>
## Phase Boundary

Mark rooms as public and sync their nodes across connected peers using Y.js CRDTs. Metadata-only replication (same SEC-03 boundary Phase 15 established). Incremental sync — peers exchange state vectors and apply only the missing updates. Offline peers queue changes and catch up automatically via y-protocols step 1+2 on reconnect. Delivers `share room`, `unshare room`, and the background sync protocol. No federated search yet — that is Phase 17.

</domain>

<decisions>
## Implementation Decisions

### Y.js Architecture & Persistence
- Use **y-protocols/sync** messages directly over a custom libp2p stream handler (`/wellinformed/share/1.0.0`) — no y-websocket/y-webrtc dep, no broken y-libp2p fork
- One **Y.Doc per shared room** — isolation, independent sync streams, per-room backpressure
- Y.Docs persisted as binary files at `~/.wellinformed/ydocs/<room>.ydoc` using `encodeStateAsUpdate`/`applyUpdate` native format
- Atomic writes via tmp+rename (reuse the pattern from peer-store.ts `savePeers`)
- Debounced observer: Y.Doc changes flush to in-memory graph within 200ms; graph.json saves on its normal cycle — graph.json remains authoritative for search/ask commands

### libp2p Sync Protocol Design
- Protocol ID: `/wellinformed/share/1.0.0` (versioned for forward compatibility)
- One persistent libp2p stream per **(peer, room) pair** — yamux multiplexes them, per-room backpressure is clean
- Symmetric room negotiation on connect: both sides exchange `SubscribeRequest` listing their locally-shared rooms, reply with the intersection
- Standard y-protocols **sync step 1 (state vector) + sync step 2 (missing updates)** — no custom diffing, handles offline catchup (SHARE-06) natively via Y.js state vectors

### Share / Unshare Semantics
- `share room X` — creates/loads the Y.Doc, runs `auditRoom` security scan, blocks on any flagged node, registers room in `~/.wellinformed/shared-rooms.json`, immediately pushes `SubscribeRequest` to all currently-connected peers
- `unshare room X` local effect — removes room from registry, closes active Y.Doc streams, **keeps the local .ydoc file** so a future `share room X` resumes from current state
- `unshare room X` remote effect — peers receive a `ROOM_UNSHARED` signal and stop receiving updates but **keep previously-imported nodes** (imported nodes are knowledge; deleting them would be hostile)
- New shared-rooms registry at `~/.wellinformed/shared-rooms.json` with `version: 1` field (mirrors peers.json schema pattern)

### Security Integration & Provenance
- Secrets scanner runs: **(a)** on `share room X` — hard-block the share if any node in the room is flagged; **(b)** on every outbound update before pushing to the Y.Doc; **(c)** on every inbound update before applying to the local Y.Doc — symmetric block-on-match
- Inbound blocked updates are logged and silently dropped (no back-propagation of the rejection — don't leak the scan verdict to the peer)
- Node provenance: every imported node carries `_wellinformed_source_peer: <peerId>` as an extra GraphNode field (SEC-03-compatible, it's metadata not content)
- Append-only audit trail at `~/.wellinformed/share-log.jsonl` — one JSON line per update: `{timestamp, peer, room, nodeId, action, allowed|blocked, reason?}`

### Claude's Discretion
- Exact debounce timing within the 200ms ceiling
- Internal message framing on libp2p streams (length-prefixed, single-JSON-per-message, etc.)
- Whether `share room` persists the in-memory Y.Doc immediately or lazily on first update

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `src/domain/sharing.ts` — `ShareableNode`, `scanNode`, `auditRoom`, `buildPatterns` (14 secret patterns including private-key blocks, slack, Google, github-pat-fine). Phase 16 calls these on every in/outbound update
- `src/infrastructure/peer-transport.ts` — `createNode`, `dialAndTag`, `getNodeStatus`. Phase 16 adds a libp2p `handle()` call to register `/wellinformed/share/1.0.0`
- `src/infrastructure/peer-store.ts` — `mutatePeers` transactional helper + the cross-process lock pattern. Reuse the lock primitives for `shared-rooms.json` mutations
- `src/infrastructure/graph-repository.ts` — `fileGraphRepository` loads/saves graph.json. Phase 16 needs an `upsertNode` call path that the Y.Doc observer can drive
- `src/domain/graph.ts` — `upsertNode`, `nodesInRoom`, `GraphNode` type

### Established Patterns
- Functional DDD: pure domain types in `src/domain`, all I/O in `src/infrastructure`
- neverthrow Result/ResultAsync for all fallible ops — no throws
- Atomic file writes: tmp file + rename (see peer-store.ts `savePeers`)
- Cross-process lock: sibling `.lock` file via POSIX exclusive-create (see peer-store.ts `acquireLock`)
- Versioned JSON files with top-level `version: 1` (see peer-store.ts `PeersFile`)
- Error unions per bounded context (see `PeerError`, `ScanError`, `GraphError` in errors.ts). Phase 16 adds `ShareError`
- CLI pattern: `(args: string[]) => Promise<number>` with subcommand routing
- `formatError` exhaustive switch — adding a new error variant triggers a TS error at every call site

### Integration Points
- `src/cli/commands/share.ts` — currently has only the `audit` subcommand. Phase 16 adds `room <name>` and `unshare <name>`
- `src/cli/index.ts` — `share` command is already registered; just extending its subcommands
- `src/infrastructure/config-loader.ts` — add `SharingConfig { debounce_ms, max_streams_per_peer }` section if needed
- `src/domain/errors.ts` — add `ShareError` variants (ShareAuditBlocked, YDocLoadError, SyncProtocolError, InboundUpdateRejected) and wire into `AppError` + `formatError`

</code_context>

<specifics>
## Specific Ideas

- Dep budget: `yjs` + `y-protocols` — 2 new npm deps (both verified on npm registry 2026-04-12)
- y-protocols provides `sync.js` (state vector + update encoding) and `awareness.js` (presence). Phase 16 uses only the sync messages
- Y.js `encodeStateVector(doc)` + `encodeStateAsUpdateV2(doc, stateVector)` are the exact primitives for SHARE-05 incremental sync
- The existing `share audit` command already uses `fileGraphRepository` — Phase 16's `share room` reuses the same load path before calling `auditRoom`
- Provenance field `_wellinformed_source_peer` survives the GraphNode round-trip because GraphNode has a catch-all `Readonly<Record<string, unknown>>` intersection
- Phase 15 review identified "one libp2p node per CLI command" as a Phase 16 risk. Phase 16 introduces a background process only if needed for sync — alternatively, sync runs inside the daemon loop (Phase 6 infrastructure)

</specifics>

<deferred>
## Deferred Ideas

- Federated **search** across the P2P network — Phase 17
- Peer **discovery** (mDNS, DHT) — Phase 17
- Production networking (NAT traversal, multiplexed streams, bandwidth mgmt) — Phase 18
- Room-level ACL ("peer P may read room R but not room S") — noted as a Phase 15 review risk; revisit when real ACL needs emerge
- `share clear <room>` destructive command (tombstones imported nodes) — reserve the command name, defer implementation
- Reputation system / trust graph — v3

</deferred>
