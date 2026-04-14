# Session Handoff — v2.1 Path B (Rust retrieval hot path)

**Drafted:** 2026-04-14 → 15 (overnight session)
**Session span:** ~12-hour work session covering v2.0 milestone close, 9-agent audit synthesis, and v2.1 Phase 24-29 execution
**Commits this session:** 21 on `main`, no pushes (user policy: commits only, no git push)
**Last commit:** `6b5d7e1 bench: Phase 25 FULL gate result — bge-base SciFact 75.22% via Rust embedder`

---

## 1. What was accomplished this session

### v2.0 milestone close (earlier in session)
- Honest 4-wave SOTA benchmark story for v2.0 shipped (`b893004`)
- v2.0 milestone block added to `MILESTONES.md` (`0817df5`)
- v2.1 candidates doc drafted with 4 paths and a recommendation (`1467085`)
- Candidate A re-scoped to 3 phases after code call-site survey (`89ac26a`)

### Audit synthesis (9 independent perspectives)
- 3 earlier expert audits ran inline in conversation: system architect, data scientist, sacred-geometry mathematician
- 6 skill-based audits written to `.planning/audits/`: S2 geometry, AI solution architect, enterprise architect, senior data scientist, data researcher, senior data engineer
- All 9 consolidated into `.planning/V2.1-SYNTHESIS.md` (`e1d1c53`) with Path A / Path B / Path C options and Path B recommendation

### Phase 21 bench-truth fixes (earlier in session, committed via `846262d` + `b6db6f2`)
- BM25 sanitizer: quoted-OR → Anserini-style bag-of-words with Lucene stopwords and `bm25(0.9, 0.4)`
- Graded NDCG: `rel.has(id) ? 1 : 0` → `rel.get(id) ?? 0`
- Paired-bootstrap comparator (`scripts/bench-compare.mjs`)
- Query-length gate added, then REMOVED (data-researcher finding: gate was the real ArguAna killer, not BM25)

### Phase 22 embedder hardening (via `3770db4`)
- `XenovaOptions.maxLength` (default 8192 for nomic context)
- `XenovaOptions.pooling` ('mean' | 'cls' | 'last' — BGE requires cls)
- `XenovaOptions.quantized` (default `false` — Xenova's 2.x default of int8 silently degrades retrieval ~10-15%)

### Phase 23 pipeline unification (`36c1640`)
- `src/domain/vectors.ts`: added `sanitizeForFts5`, `rrfFuse`, `HybridConfig`, `DEFAULT_HYBRID_CONFIG`, `LUCENE_STOPWORDS`
- `src/infrastructure/vector-index.ts`: `VectorIndex` port gains `searchHybrid` and `searchByRoomHybrid`. Schema adds `fts_docs` FTS5 virtual table + `raw_text` column to `vec_meta`. Backward-compat migration via ALTER TABLE + CREATE VIRTUAL TABLE IF NOT EXISTS on open.
- `src/application/use-cases.ts`: `indexNode` passes `raw_text` through, `searchGlobal` and `searchByRoom` now call hybrid variants internally.
- `tests/bench-real.test.ts`: retrieval regression bar tightened from `>= 0` to `MRR >= 0.62`, `NDCG@5 >= 0.60`, `Recall@5 >= 0.55`, `Precision@5 >= 0.25`.
- 313/313 tests pass post-refactor.

### 🏆 The Big Finding (middle of session)
**`Xenova/bge-base-en-v1.5` is a defective ONNX port** — measured -11.4 NDCG@10 on BEIR SciFact vs the published BAAI ceiling. Pooling fixes, quantization fixes, and max_length fixes all failed to move the number. Rust `fastembed-rs` (which downloads Qdrant-curated ONNX weights) matches published at 74.70% — a +11.41 NDCG gap driven by weight quality, not pipeline code. Committed as `9c6e00f`.

Scope of the defect:
- `Xenova/bge-base-en-v1.5`: **−11.4 NDCG** (defective)
- `Xenova/nomic-embed-text-v1.5`: −0.4 NDCG (correct port)
- `Xenova/all-MiniLM-L6-v2`: matches reference (correct port)

Only bge-base is broken.

### Phase 24 — Rust embed_server (`3d35123`)
- New Cargo crate `wellinformed-rs/` (DDD layout, clippy pedantic `-D warnings` clean)
- Binary: `wellinformed-rs/src/bin/embed_server.rs` — stdio JSON-RPC, lazy-loaded encoder registry
- Ops: `embed`, `ping`, `shutdown`
- TS adapter: `rustSubprocessEmbedder` in `src/infrastructure/embedders.ts` — single-flight FIFO request queue, lazy subprocess startup, Result monad error propagation
- End-to-end smoke test: single embed + batch both work, byte-exact match with Rust-native CLI

### Phase 25 — runtime wiring + gate bench (`4ddf3fb`)
- `src/cli/runtime.ts`: `buildEmbedder(modelCache)` factory selects backend via `WELLINFORMED_EMBEDDER_BACKEND = 'xenova' | 'rust'` env var
- Model/dim/path via `WELLINFORMED_EMBEDDER_MODEL` and `WELLINFORMED_RUST_BIN` env vars
- Default stays `xenova` (backward compat — no user sees a change)
- `scripts/bench-beir-rust.mjs`: BEIR runner that uses `rustSubprocessEmbedder` + production `openSqliteVectorIndex.searchHybrid`

**Phase 25 gate results (committed in `6b5d7e1`):**

| Pipeline | SciFact NDCG@10 | vs Published 74.04% |
|----------|----------------|----------------------|
| **TS prod searchHybrid × Rust bge-base** | **75.22%** | **+1.18** |
| Rust-native dense-only (fastembed) | 74.70 | +0.66 |
| Published BAAI bge-base (MTEB) | 74.04 | baseline |
| TS Xenova bge-base (defective) | 63.29 | −10.75 |
| TS nomic Phase 21 hybrid (prior best) | 72.90 | −1.14 |

- **Delta over defective Xenova**: +11.93 NDCG
- **Delta over prior best TS number**: +3.20 NDCG
- Latency: p50 = 11 ms, p95 = 15 ms
- Indexing: 3.4 docs/sec (Rust fp32 bge-base cost)
- Recall@10: 87.86% (matches published 87.42% within 0.44)

Also measured: TS prod searchHybrid × Rust MiniLM → 72.02% on SciFact (+6.75 over Rust-native dense-only, confirming hybrid lift composes cleanly through the subprocess embedder).

### Phase 27+28 — RNG tunnels + pilot-centroid routing (`03e2956`)
- `wellinformed-rs/src/domain/tunnel_graph.rs`: new pure domain module implementing the Relative Neighborhood Graph (mathematician Proposal B). Replaces `findTunnels` O(n²) with O(n × k² × d) via rayon-parallel brute-force kNN + Jaromczyk-Toussaint RNG test. Tunnels become structural cross-color Delaunay-approx edges, sorted by ascending distance.
- `wellinformed-rs/src/domain/room_routing.rs`: new pure domain module with `compute_centroids` + `route_to_rooms`. Implements RouterRetriever-style (AAAI 2025, arXiv:2409.02685) pilot-centroid routing. Pure fold-and-normalize.
- `embed_server` protocol gains `find_tunnels` and `compute_centroids` ops — both stateless one-shot requests where the client uploads the labeled vector set per call.
- `src/infrastructure/rust-retrieval.ts`: new TS adapter `spawnRustRetrievalClient` — same subprocess management pattern as Phase 24, exposing `findTunnels` + `computeCentroids` via neverthrow Result.

**Feasibility smoke (explicit user instruction: feasibility before unit tests):**
- Ping → `{"ok":true,"version":"0.1.0"}`
- find_tunnels on 4 vectors in 2 rooms → 2 tunnels at exact dist √0.02 = 0.1414
- compute_centroids → r1 = `[1/√2, 1/√2, 0]` (exact normalized mean), r2 = `[0, 0, 1]`
- TS adapter round-trips Float32Array ↔ JSON wire ↔ Rust `Vec<f32>` lossless at 4-decimal precision

### Phase 29 — CI retrieval regression bar (`3e1b012`)
- `tests/phase29.rust-retrieval-regression.test.ts` — 3 subtests:
  1. End-to-end NDCG@10 ≥ 0.70 on a 10-passage × 5-query fixture through TS production `searchHybrid` × Rust MiniLM embedder
  2. RNG tunnel detection on a 4-vector fixture — asserts 2 cross-room tunnels with correct distance ordering
  3. Pilot-centroid computation on 3-vector fixture — asserts normalized mean arithmetic
- All 3 skip cleanly if the Rust binary isn't present (Phase 30 will ship prebuilt binaries via npm postinstall; until then skip-on-missing keeps CI green for contributors without a Rust toolchain)

Test file exists, typechecks clean. **Has NOT been successfully run yet** — the last attempt used `| tail -40` which buffered the output; re-run without the pipe was interrupted by the user's handoff request.

---

## 2. What's NOT done (pending work for next session)

### 2a. Phase 29 test execution
The Phase 29 regression bar test file is committed but has not been observed to pass end-to-end on the real Rust binary yet. **Resume action:**
```bash
cd /Users/saharbarak/workspace/wellinformed
node --import tsx --test tests/phase29.rust-retrieval-regression.test.ts
```
Expected: all 3 subtests pass. If any fail, investigate before the next merge.

### 2b. Multi-dataset validation
Phase 25 full gate was measured on **SciFact only**. The remaining 4 BEIR datasets (NFCorpus, ArguAna, SciDocs, FiQA) are not yet measured through the TS production × Rust embedder path. **Resume action:**
```bash
for ds in nfcorpus arguana scidocs fiqa; do
  node scripts/bench-beir-rust.mjs $ds --model bge-base
done
```
Expected results (based on published bge-base MTEB scores + Phase 23 hybrid lift):
- NFCorpus: 38-40 NDCG@10 (published dense ~38)
- ArguAna: 60-64 (published dense 63.6)
- SciDocs: 21-23 (published dense 21.7)
- FiQA: 42-44 (published dense 40.7)

This is ~4 hours of compute. Would produce a 5-dataset BEIR table that silences the cherry-picking concern.

### 2c. Phase 30 — Rust binary distribution
Prebuilt binaries via npm postinstall (user's pick earlier: "npm postinstall with prebuilt per-platform binaries — matches better-sqlite3"). Not shipped. **Without this, every user has to `cargo build --release` inside `wellinformed-rs/` before they can use the Rust backend.**

Architecture notes: `better-sqlite3` pattern uses `node-pre-gyp` to download platform-specific prebuilds from GitHub Releases on install. For `wellinformed-rs` this means:
1. GitHub Actions workflow that builds the Rust binary on 3+ platforms (macOS arm64, macOS x86_64, linux x86_64)
2. Uploads to a Release
3. `package.json` postinstall script fetches the right binary
4. Sets `WELLINFORMED_RUST_BIN` env-equivalent at module load

### 2d. Open questions from the 9-agent synthesis
The user picked defaults for 4 of 5 questions earlier ("locking in unless you override"):
- ✅ Plan A (Path B) — picked, in execution
- ✅ Room routing: pilot-centroid first, hyperbolic only if pilot fails gate — pilot-centroid shipped (Phase 28), hyperbolic NOT shipped (deferred to v2.3 research sprint)
- ⚠ Rust binary distribution: npm postinstall prebuilts — AGREED but NOT YET SHIPPED (Phase 30 open)
- ✅ IPC: stdio JSON-RPC — shipped
- ✅ Phase 30 debt cleanup: deferred to v2.2 — deferred

### 2e. Production `wellinformed ask` validation
Nobody has yet run `wellinformed ask "query"` with `WELLINFORMED_EMBEDDER_BACKEND=rust WELLINFORMED_EMBEDDER_MODEL=bge-base` set and observed the Rust backend serving live queries through the MCP tool surface. **This is the user-facing validation that Phase 24-25 actually deliver on the promise.**

**Resume action:**
```bash
WELLINFORMED_EMBEDDER_BACKEND=rust \
WELLINFORMED_EMBEDDER_MODEL=bge-base \
wellinformed ask "functional DDD neverthrow Result monad"
```
Expected: results that are semantically similar to current `wellinformed ask` (probably nearly identical ranking since the indexed graph was produced with Xenova MiniLM — an existing-corpus retrieval still uses the stored MiniLM vectors, not the Rust bge-base path). **The real test is re-indexing the graph with Rust bge-base then asking.** That requires a full `wellinformed index` pass (~20 min at 3.4 docs/sec on a 9k-node graph).

### 2f. Potential issue: Phase 28 room routing has no gate test yet
Phase 28 shipped the pilot-centroid Rust domain function and the `compute_centroids` op, but there is NO measured validation that routing actually improves retrieval on a multi-room benchmark (CQADupStack or similar). **The data researcher's Simpson's paradox finding says rooms DO help on hard sub-populations, but we haven't re-run Wave 4 with pilot-centroid routing to confirm the lift.**

**Resume action:** run a modified `bench-room-routing.mjs` that:
1. Indexes all 3 subforums with Rust bge-base
2. Computes pilot centroids via `spawnRustRetrievalClient.computeCentroids`
3. For each query, routes by nearest centroid, searches only that room's corpus
4. Compares aggregate NDCG@10 to flat search

If +1 NDCG (beating data researcher's per-room Simpson's finding aggregate), Phase 28 is validated. If null, document it and fall back to "rooms are filter not score."

---

## 3. Current commit sequence (last 12)

```
6b5d7e1 bench: Phase 25 FULL gate result — bge-base SciFact 75.22% via Rust embedder
3e1b012 test(phase-29): CI retrieval regression bar for Rust-backed pipeline
03e2956 feat(phase-27+28): RNG tunnels + pilot-centroid room routing
4ddf3fb feat(phase-25): wire rustSubprocessEmbedder into runtime + gate bench
3d35123 feat(phase-24): Rust embed_server stdio binary + TS adapter
e1d1c53 docs: v2.1 9-agent synthesis + Path B (Rust retrieval hot path)
9c6e00f bench: the big finding — Xenova bge-base ONNX port is defective (-11 NDCG)
(... audit commits ...)
36c1640 refactor(phase-23): pipeline unification + bench truth + embedder hardening
3770db4 fix(embedders): expose max_length, default to 8192 (nomic context window)
b6db6f2 bench: Phase 21 measurement — SciFact +0.60 NDCG@10 from sanitizer fix alone
846262d bench: Phase 21 — fix BM25 sanitizer, graded NDCG, paired bootstrap, query-length-gated hybrid
b893004 bench: 4-wave SOTA story — Wave 2 at 72.30% is CPU-local ceiling
```

---

## 4. Critical state / tests / runs

**TS test suite:** 313/313 pass post all Phase 21/22/23/24/25/27/28 refactors. Does NOT yet include Phase 29 regression bar (skips on missing Rust binary — binary IS built locally so skip branch won't fire, but the 3 subtests haven't been observed to pass end-to-end yet).

**Rust workspace:** `wellinformed-rs/` — lib + 2 bins (`wellinformed-bench`, `embed_server`)
- cargo clippy pedantic `-D warnings` clean on all targets
- cargo test (not yet run in current state; user explicit instruction: skip unit tests, feasibility only)
- Release build: `target/release/wellinformed-bench` (24 MB), `target/release/embed_server` (24 MB)

**Benchmark cache** (at `~/.wellinformed/bench/`):
- SciFact datasets cached, indexed with multiple encoders
- Latest measurements in:
  - `scifact__nomic-ai-nomic-embed-text-v1-5__hybrid/results.json` — Phase 21 SciFact
  - `arguana__nomic-ai-nomic-embed-text-v1-5__hybrid/results.json` — gate-removed ArguAna
  - `scifact__xenova-bge-base-en-v1-5__hybrid/results.json` — Xenova defect (63.29%)
  - `scifact__rust__nomic/results.json` — Rust dense nomic
  - `scifact__rust__bge-base/results.json` — Rust dense bge-base (74.70% — confirms Xenova defect)
  - `scifact__rust-via-ts__minilm/results.json` — Phase 25 MiniLM gate (72.02%)
  - `scifact__rust-via-ts__bge-base/results.json` — **Phase 25 FULL gate (75.22%)**

---

## 5. How to resume this session cleanly

1. **Verify build is current:**
   ```bash
   cd /Users/saharbarak/workspace/wellinformed
   npm test                                                          # should be 313/313
   source $HOME/.cargo/env
   cargo build --release --manifest-path wellinformed-rs/Cargo.toml  # ~30s incremental
   ```

2. **Run Phase 29 quality gate test** (validates Rust backend through production TS path):
   ```bash
   node --import tsx --test tests/phase29.rust-retrieval-regression.test.ts
   ```
   Expected: 3 subtests pass, mean NDCG@10 ≥ 0.70 on the fixture.

3. **Run the multi-dataset validation sweep** (Section 2b above) — ~4h compute.

4. **Pick up v2.1 Phase 30 (binary distribution)** — the last piece before v2.1 can be considered shippable.

5. **Decide on v2.1 milestone close** — v2.1 currently has 5 shipped phases (24, 25, 27, 28, 29) + 1 pending (30). Once Phase 30 lands and multi-dataset validation passes, run `gsd:complete-milestone` for v2.1.

---

## 6. Context for the next session

**Coding standards** (from user memory `feedback_coding_style.md` + `feedback_no_piling_models.md`):
- Strict functional style — neverthrow Results, iterator chains, no mutable state outside encoder sessions
- No classes in domain/application layers
- Clippy pedantic `-D warnings` on Rust
- No piling models — every retrieval optimization needs a principled mechanism AND a measured gate

**Git policy** (from user memory `user_git_identity.md`):
- User: SaharBarak <sahr.h.barak@gmail.com>
- Never use claude/anthropic co-authors
- No autonomous `git push` — commits only, user reviews before push

**Open decisions pending user input:**
- Phase 30 (binary distribution): npm postinstall prebuilt confirmed but not yet executed
- Phase 28 validation (room routing on CQADupStack): needed to confirm the Simpson's paradox win
- v2.1 vs v2.2 scope line: currently v2.1 = Phases 24-30. Phase 30 may slip to v2.2 if npm postinstall turns out to need a GH Release workflow that doesn't exist yet.

**The Big Finding (for context when resuming):**
Xenova/bge-base-en-v1.5 is broken by -11 NDCG. fastembed-rs's Qdrant-curated ONNX ports work. The Rust crate was built as a *scientific instrument* to A/B test weight quality, and it discovered that the language comparison was the wrong framing — the real comparison was Xenova weights vs Qdrant weights. Same language overhead, 11-point quality gap from packaging.

---

## 7. What's the one sentence?

**v2.1 Path B Phases 24-29 are code-complete and Phase 25 is measured at 75.22% NDCG@10 on SciFact — beating the published BAAI ceiling by +1.18 and the prior best TS number by +3.20 — pending Phase 29 test execution, multi-dataset validation, and Phase 30 binary distribution before v2.1 can ship.**
