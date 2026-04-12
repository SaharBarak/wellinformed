# Requirements: wellinformed v2.0

**Defined:** 2026-04-12
**Core Value:** A decentralized knowledge graph where every coding agent shares what it learned.

## v2.0 Requirements

### Peer Identity & Management

- [x] **PEER-01**: Each wellinformed instance has an ed25519 keypair generated on first run, stored at ~/.wellinformed/peer-identity.json
- [x] **PEER-02**: `wellinformed peer add <multiaddr>` connects to a remote peer via js-libp2p
- [x] **PEER-03**: `wellinformed peer remove <id>` disconnects and removes a peer
- [x] **PEER-04**: `wellinformed peer list` shows connected peers with status, latency, shared rooms *(Phase 15: stored peers only; live status / latency / shared rooms land with Phase 18 NET layer)*
- [x] **PEER-05**: `wellinformed peer status` shows own identity, public key, connected peer count

### Security & Privacy

- [x] **SEC-01**: Secrets scanner runs on every node before sharing — detects API keys (sk-, ghp_, AKIA), tokens, passwords, .env patterns
- [x] **SEC-02**: Flagged nodes are BLOCKED from sharing with a clear warning
- [x] **SEC-03**: Shared nodes carry only: id, label, room, embedding_id, source_uri, fetched_at. No raw text, no content_sha256, no file contents, and no raw embedding vectors.

    **Rationale for `embedding_id` (reference) instead of `embedding_vector` (raw float array) — revised 2026-04-12:** Embedding-inversion attacks can recover approximate source text from sentence-transformer vectors (Morris et al. 2023, "Text Embeddings Reveal Almost As Much As Text"). Sharing raw vectors would make the metadata boundary porous — a peer receiving vectors could reconstruct private content the user never meant to leak. Phase 15 ships `embedding_id` as a stable reference so receivers know which embedding slot a node occupies locally, but the vector itself is never transmitted. Cross-peer semantic search (Phase 17) must re-embed from `source_uri + label` on the receiving side rather than trusting imported vectors. This is a stronger security model than the original spec and should be preserved through Phase 16+.
- [x] **SEC-04**: `wellinformed share audit --room X` shows exactly what would be shared before enabling
- [x] **SEC-05**: All P2P traffic encrypted via libp2p Noise protocol
- [x] **SEC-06**: Peer authentication via ed25519 signature verification

### Room Sharing

- [x] **SHARE-01**: `wellinformed share room <name>` marks a room as public (shared with connected peers)
- [x] **SHARE-02**: `wellinformed unshare room <name>` makes a room private again
- [x] **SHARE-03**: Shared rooms sync via Y.js CRDT — concurrent edits from multiple peers converge
- [x] **SHARE-04**: Only metadata + embeddings replicate (node labels, vectors, edges) — not raw source text
- [x] **SHARE-05**: Sync is incremental — only new/changed nodes since last sync
- [x] **SHARE-06**: Offline changes queue and sync automatically when peers reconnect

### Federated Search

- [ ] **FED-01**: `wellinformed ask "query" --peers` searches across all connected peers' shared rooms
- [ ] **FED-02**: Results aggregated and re-ranked by distance across all peers
- [ ] **FED-03**: Each result shows which peer it came from
- [ ] **FED-04**: Tunnel detection runs across peers — cross-peer + cross-room connections surfaced
- [ ] **FED-05**: MCP tool `federated_search` lets Claude search the P2P network mid-conversation

### Peer Discovery

- [ ] **DISC-01**: Manual peer add via multiaddr (always works, no infrastructure needed)
- [ ] **DISC-02**: mDNS/Bonjour auto-discovery for peers on the same local network
- [ ] **DISC-03**: DHT-based discovery for internet-wide peer finding (libp2p Kademlia)
- [ ] **DISC-04**: Optional coordination server for bootstrapping (lightweight, stateless)

### Production Networking

- [ ] **NET-01**: js-libp2p transport with multiplexed streams
- [ ] **NET-02**: Bandwidth management — configurable sync rate, no flooding
- [ ] **NET-03**: NAT traversal via libp2p relay + hole punching
- [ ] **NET-04**: Connection health monitoring with auto-reconnect

## v3 Requirements (deferred)

- **V3-01**: Reputation system — peers that share valuable content rank higher
- **V3-02**: Incentive layer — token-based rewards for sharing rare knowledge
- **V3-03**: Federated learning — train shared embedding models across the network
- **V3-04**: Global knowledge index — searchable directory of all public rooms across all peers

## Out of Scope

| Feature | Reason |
|---------|--------|
| Blockchain/crypto integration | Complexity, no clear value for v2 |
| Raw text sharing | Privacy risk — metadata + embeddings only |
| Anonymous peers | All peers authenticated via ed25519 |
| Central server dependency | P2P by design — server is optional bootstrap only |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| PEER-01..05 | Phase 15 | Pending |
| SEC-01..06 | Phase 15 | Pending |
| SHARE-01..06 | Phase 16 | Pending |
| FED-01..05 | Phase 17 | Pending |
| DISC-01..04 | Phase 17 | Pending |
| NET-01..04 | Phase 18 | Pending |

**Coverage:**
- v2.0 requirements: 30 total
- Mapped to phases: 30
- Unmapped: 0 ✓

---
*Requirements defined: 2026-04-12*
