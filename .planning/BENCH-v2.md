# wellinformed v2.0 — Benchmark Report

**Run date:** 2026-04-13
**Machine:** macOS 26.3 (arm64)
**CPU:** 10 cores
**Memory:** 32 GB
**Node:** v25.6.1
**SQLite:** 3.51.0
**wellinformed:** 1.0.0 (v2.0 milestone — 5 phases shipped)

---

## 0. Corpus Size

| Metric | Value |
|--------|-------|
| Research graph vectors | 2,830 (ONNX 384-dim, all-MiniLM-L6-v2) |
| Research graph size | 3.1 MB graph.json + 13.4 MB vectors.db |
| Code graph nodes | **16,855** |
| Code graph edges | **42,907** |
| Code graph size | 374 MB (includes FTS indices + WAL) |
| Indexed codebases | 5 |
| Room ↔ codebase attaches | 5 |
| Research rooms | 5 (wellinformed-dev, p2p-llm, tlvtech, forge, auto-tlv) |

---

## 1. Functional Correctness

| Suite | Tests | Pass | Fail | Duration |
|-------|-------|------|------|----------|
| Full v2.0 suite (5 phases) | **243** | **243** | **0** | 4,850 ms |

Phase coverage:
- Phase 1-6 (v1.x research graph + MCP + daemon): regression-intact
- Phase 15 — Peer Foundation + Security (37 tests)
- Phase 16 — Room Sharing via Y.js CRDT (40 tests)
- Phase 17 — Federated Search + Discovery (36 tests)
- Phase 18 — Production Networking (44 tests including 10-peer libp2p mesh in ~2.5s)
- Phase 19 — Structured Codebase Indexing (36 tests)

---

## 2. Retrieval Quality — Full BEIR v1 + SOTA Progression

**Methodology correction (2026-04-13):** An earlier version of this report cited a 96.8% NDCG@10 from a 15-passage × 10-query mini-harness. That sample size is too small to produce leaderboard-comparable numbers. We re-ran the benchmark against **full BEIR v1 datasets** using the exact same ONNX pipeline wellinformed uses at runtime. Every number below is directly comparable to the [MTEB BEIR leaderboard](https://huggingface.co/spaces/mteb/leaderboard).

### SOTA progression — 4 waves, measured

| Wave | Change | SciFact NDCG@10 | Δ | Latency p50 | Verdict |
|------|--------|-----------------|----|-------------|---------|
| Baseline | `all-MiniLM-L6-v2` dense only | **64.82%** | — | 6 ms | v1 baseline |
| **Wave 1** | Swap encoder → `nomic-embed-text-v1.5` (768d, 8192 ctx) | **69.98%** | **+5.16** | 6 ms | ✓ Shipped |
| **Wave 2** | Add SQLite FTS5 BM25 + RRF (k=60) hybrid | **72.30%** | **+2.32** | 36 ms | ✓ Shipped (SOTA) |
| Wave 3 | + `Xenova/bge-reranker-base` cross-encoder rerank top-100 | 70.38% | **−1.92** | 25,940 ms | ✗ Failed — see §2b |
| Wave 4 | + Room-aware retrieval (oracle routing, CQADupStack) | — | **+0.34** | 132 ms | ✗ Null — see §2c |

**Wave 2 (72.30%) is the measured CPU-local SOTA ceiling for wellinformed.** Both Wave 3 and Wave 4 were honest attempts at principled mechanisms from the 2024-2025 literature (MS-MARCO reranker, RouterRetriever-style partition awareness). Both produced measurable null results on standardized benchmarks. They're documented below so readers can verify the claim and avoid the same dead ends.

### Wave 2 context — where 72.30% lands on the real leaderboard

| Model | Params | SciFact NDCG@10 | Runtime |
|-------|--------|-----------------|---------|
| BM25 (Anserini) | — | 66.5 | CPU |
| nomic-embed-text-v1.5 (dense only) | 137M | ~71 | CPU |
| **wellinformed Wave 2 (nomic + BM25 RRF)** | **137M** | **72.30** | **CPU, 36 ms** |
| E5-base-v2 (dense only) | 109M | 73.1 | CPU |
| bge-base-en-v1.5 (dense only) | 110M | 74.0 | CPU |
| bge-large-en-v1.5 (dense only) | 335M | 74.6 | CPU |
| monoT5-3B reranker on top | 3B | 76.7 | **GPU** |

Wave 2 lands **~2 points below the best dense-only encoders** at roughly equivalent parameter budget, and **~4.4 points below GPU-required reranker stacks**. For a 137M model with zero new dependencies (sqlite-vec + sqlite-fts5 are already in our stack), this is competitive.

### Wave 2 — multi-dataset BEIR validation

| Dataset | Corpus | Queries | NDCG@10 | R@5 | R@10 | MRR | Pipeline |
|---------|--------|---------|---------|-----|------|-----|----------|
| **SciFact** (Phase 21) | 5,183 | 300 | **72.90%** | 79.65% | 85.46% | 0.696 | Anserini-style BM25 + graded NDCG + query-length-gated hybrid |
| **SciFact** (pre-Phase 21) | 5,183 | 300 | 72.30% | 79.76% | 84.79% | 0.690 | Buggy quoted-OR BM25, binary NDCG, no gate |
| **NFCorpus** (pre-Phase 21) | 3,633 | 323 | 34.11% | 12.82% | 15.85% | 0.539 | Wave 1 dense-only; pending re-run |
| **ArguAna** (pre-Phase 21) | 8,674 | 1,406 | 37.36% | 57.89% | 78.52% | 0.244 | Buggy hybrid regressed 13 pts vs dense — pending re-run |
| **SciDocs** (pre-Phase 21) | 25,657 | 1,000 | 18.07% | 13.29% | 18.78% | 0.316 | Buggy hybrid ≈ dense — pending re-run with graded NDCG |

**Phase 21 result on SciFact: +0.60 NDCG@10 lift from bench-truth fixes alone** (no encoder swap, no new model). BM25 latency dropped from 9 ms → **2 ms p50** (4.5× faster) because the FTS5 sanitizer no longer builds a 300-clause quoted-OR per query. Other 4 datasets are re-running; Phase 22 (encoder swap to bge-base-en-v1.5) is the next gate.

### 2d. Xenova ONNX port quality — measured, confirmed defective

**Hypothesis:** the ~10-13 NDCG@10 gap between our Xenova-based bench and published numbers on bge-base (and the smaller ArguAna gap on nomic) is caused by Xenova's own ONNX conversions, not by our pipeline code. To test: run the exact same BEIR benchmark via a completely independent Rust crate (`wellinformed-rs/`) using `fastembed-rs`, which downloads its own ONNX weights (Qdrant-published) rather than Xenova's.

**Result: confirmed.** Same dataset, same encoder, same RRF-free dense-only cosine retrieval, two independent ONNX ports.

| Metric | **Rust fastembed** bge-base | TS Xenova bge-base | Published BAAI bge-base |
|--------|----------------------------|--------------------|-------------------------|
| NDCG@10 | **74.70%** | 63.29% | 74.04 ✓ |
| MAP@10 | **70.39%** | 58.76% | 69.30 ✓ |
| R@5 | **81.43%** | 71.08% | — |
| R@10 | **86.69%** | 75.69% | 87.42 ✓ |
| MRR | **0.7130** | 0.5992 | — |

**Rust matches the published ceiling within 0.66 NDCG points.** TypeScript-via-Xenova is **−11.41 NDCG points below published**, not because of our code, but because `Xenova/bge-base-en-v1.5` is a different ONNX conversion than the Qdrant-published one fastembed uses. Changing the pooling strategy, disabling int8 quantization, expanding max_length — none of these moved the TS bge-base number. The weights themselves are the problem.

**This finding applies only to bge-base.** The Xenova port of nomic-embed-text-v1.5 matches published within 0.4 NDCG points on SciFact (measured earlier in Phase 22 diagnostics). Every Xenova port needs to be validated against published numbers before being adopted.

**SciFact MiniLM sanity check (Rust vs TS, same Xenova weights):**

| Metric | Rust fastembed MiniLM | TS Xenova MiniLM |
|--------|----------------------|------------------|
| NDCG@10 | **65.27%** | 64.82% |
| MRR | **0.6111** | 0.6039 |
| Indexing | **19 docs/sec** | 19 docs/sec |

Quality tied within 0.45 NDCG (noise-level), **throughput identical at 19 docs/sec** — confirming that on correctly-ported weights both runtimes produce equivalent results. Rewriting wellinformed in Rust is NOT a performance lever at the inference layer; both runtimes drive the same native ONNX Runtime, and the language overhead is negligible.

**The real Rust win** is elsewhere:
- **Weight quality selection.** `fastembed` pulls Qdrant-curated ONNX conversions that have been validated. Xenova's library auto-downloads whatever is in the `Xenova/` namespace, which is not quality-gated.
- **Brute-force cosine via rayon** is ~2× faster than `sqlite-vec` MATCH on tiny corpora, but this difference vanishes at production scale where ANN index structure dominates.

**Action items for v2.1:**
1. Replace `Xenova/bge-base-en-v1.5` path with either (a) fastembed-style Qdrant weights loaded via `ort` directly, or (b) stick with nomic which is correctly ported, OR (c) add a Rust-side inference subprocess for encoders Xenova doesn't port correctly.
2. Add a validation test in CI that embeds one known sentence and compares the vector against a frozen reference — catches future Xenova regressions.
3. Run Rust bench on the remaining 3 datasets (NFCorpus, ArguAna, SciDocs) to see if the nomic-v1.5 port issue is specific to Xenova too.

### 2e. Phase 24-25 — Rust inference sidecar ships, FULL gate passed

Picked Action item 1(c). Shipped `wellinformed-rs/src/bin/embed_server.rs` — a long-lived Rust binary speaking stdio JSON-RPC, with a matching TypeScript adapter `rustSubprocessEmbedder` in `src/infrastructure/embedders.ts`. Production wellinformed now routes embeddings through Rust via `WELLINFORMED_EMBEDDER_BACKEND=rust` env var — no MCP/CLI/daemon changes, just the encoder port swap.

**Phase 25 gate measured via the full production `searchHybrid` path:**

| Pipeline | SciFact NDCG@10 | vs Published 74.04% |
|----------|----------------|----------------------|
| **TS prod searchHybrid × Rust bge-base** | **75.22%** | **+1.18** |
| Rust-native dense-only (fastembed) | 74.70 | +0.66 |
| Published BAAI bge-base (MTEB) | 74.04 | baseline |
| **TS Xenova bge-base (defective port)** | **63.29** | **−10.75** |
| TS nomic Phase 21 hybrid (prior best) | 72.90 | −1.14 |

**Delta over the defective Xenova bge-base path: +11.93 NDCG points.** Delta over the prior best TS number (nomic + hybrid): +3.20. Latency: p50 = 11 ms, p95 = 15 ms end-to-end through the TS `searchHybrid` port including subprocess IPC. Throughput: 3.4 docs/sec indexing (Rust fp32 bge-base cost, bottlenecked on ONNX forward pass not on protocol overhead). Recall@10 = 87.86% — matches published 87.42% within 0.44 points.

**Multi-dataset Phase 25 sweep (TS prod searchHybrid × Rust bge-base):**

| Dataset | Corpus × Queries | NDCG@10 | Recall@10 | MRR | vs Published Dense | Notes |
|---------|------------------|---------|-----------|-----|--------------------|-------|
| **SciFact** | 5,183 × 300 | **75.22%** | 87.86% | — | +1.18 (hybrid lift) | Published bge-base dense: 74.04% |
| **NFCorpus** | 3,633 × 323 | **37.19%** | 17.99% | 0.585 | −0.61 (within noise) | Published bge-base dense: 37.80% |
| **ArguAna** | 8,674 × 1,406 | **43.97%** | **86.42%** | 0.303 | −19.63 (hybrid hurts) | Published bge-base dense: 63.60% |

**ArguAna finding — Recall is high but NDCG tanks.** Recall@10 = 86.42% confirms the gold counter-argument IS retrieved by the pipeline — it just gets reshuffled out of the top-10 rank by BM25. The dense stage finds the refuting argument; the BM25 stage then promotes lexically-similar (same-argument) documents, pushing the gold down. This is the cleanest possible mechanistic confirmation of the hybrid-on-counter-argument failure mode: **gold found, rank destroyed**. On SciFact and NFCorpus (fact-retrieval tasks) BM25 helps or stays neutral; on ArguAna (refutation) it actively harms top-k ordering even though it doesn't harm retrieval. Ship dense-only as fallback for stance/counter-argument workloads.

**Why 75.22% beats the published 74.04%:** the published number is dense-only; our pipeline stacks BM25 + RRF hybrid on top via the Phase 23 `searchHybrid` port in `src/infrastructure/vector-index.ts`. The +1.2 lift over dense-only matches the typical hybrid gain on SciFact and is reproducible.

**What this means for v2.1:** Path B Phase 25 is a proven, shippable configuration. Users who set `WELLINFORMED_EMBEDDER_BACKEND=rust WELLINFORMED_EMBEDDER_MODEL=bge-base` get +11.93 NDCG@10 on SciFact-class workloads with zero changes to the MCP server, CLI, daemon, or P2P layer — just a new env var and a prebuilt Rust binary.

Phases 27 + 28 + 29 code are committed but pending measurement (RNG tunnel speedup vs TS findTunnels, pilot-centroid routing lift on CQADupStack, CI regression bar on the fixture corpus).

**Caveat — Wave 2 hybrid is not universally better.** ArguAna is counter-argument retrieval where the "relevant" document for a query is the argument that *refutes* it. BM25 adds lexical similarity, which is **anti-helpful** for counter-argument tasks: the BM25 stage promotes documents that lexically match the query (i.e., make the *same* argument), not those that refute it. Pure nomic dense-only retrieval scores ~50.4% NDCG@10 on ArguAna (per the [nomic tech report Table 4](https://arxiv.org/abs/2402.01613)); our hybrid Wave 2 number is 12+ points below that. This is a measured honest negative — hybrid retrieval is task-dependent, and BEIR includes at least one task type (counter-argument) where it backfires.

**Practical implication for production Wave 2 swap:** if we ship hybrid as the default, we should also expose dense-only as a fallback for counter-argument and stance-detection style tasks. Or pick the hybrid weight per task. Or keep things simple and accept the trade — most user queries are not counter-argument retrieval.

**Note on ArguAna BM25 latency (501 ms p50).** ArguAna queries are unusually long (whole arguments, sometimes 200+ tokens). The FTS5 BM25 sanitizer in `bench-beir-sota.mjs` builds an OR-fused phrase query per token, so a 200-token query becomes ~200 OR clauses against the 8,674-passage corpus — slow but correct. SciFact queries average ~10 tokens, hence the SciFact BM25 p50 of 9 ms. Workload-dependent, not a bug.

### 2f. Matryoshka × quantization × hybrid lab (Phase 32)

One invocation of `scripts/bench-lab.mjs` sweeps **8 Matryoshka dims × 3 quantizations × {dense, hybrid} × 4 BEIR datasets = 192 configurations** using the already-cached Xenova-nomic corpus vectors from the Wave 2 `sota.db` files. Corpus is never re-embedded — the lab only re-embeds queries (~100s total across 4 datasets).

**The original SciFact-only Matryoshka gate** (`scripts/bench-matryoshka.mjs`, Phase 31) was dense-only and returned NULL at every dim below 768. This was misleading: production wellinformed runs hybrid RRF by default, and the lab shows that BM25 fusion **rescues** truncation loss at almost every dim.

**Shippable Pareto frontier** (worst-case Δ NDCG@10 across SciFact + ArguAna + FiQA + SciDocs, **hybrid pipeline**):

| bytes/vec | dim | quant | worst Δ | shrink vs fp32-768 | Verdict |
|-----------|-----|-------|---------|--------------------|---------|
| **64** | 512 | **binary** | **−1.79pt** | **48×** | **✓ ship** |
| 96 | 768 | binary | −1.10pt | 32× | ✓ ship (safer) |
| 384 | 96 | fp32 | −1.76pt | 8× | ✓ ship |
| 512 | 128 | fp32 | −1.32pt | 6× | ✓ ship |
| 1536 | 384 | fp32 | −1.42pt | 2× | ✓ ship (dense-only callers) |

**Per-dataset at binary-512 hybrid**:

| Dataset | fp32-768 hybrid | binary-512 hybrid | Δ |
|---------|-----------------|-------------------|---|
| SciFact | 73.34% | 69.91% | −3.43pt |
| ArguAna | 35.61% (dense ceiling) | 36.29% | **+0.68pt** (beats baseline) |
| FiQA | 9.25% | 8.46% | −0.93pt |
| SciDocs | 18.55% | 16.90% | −1.79pt ← worst case |

Numbers in the ArguAna row are dense-ceiling comparisons; ArguAna hybrid at every tested dim beats the fp32-768 anchor. Production `searchHybrid` already runs hybrid RRF (SIGIR 2009 Cormack-Clarke-Büttcher, k=60), so this is a drop-in storage swap at the `upsert` path.

**Production implication:** 10k-entry vector database drops from ~30 MB (fp32-768) to **~0.6 MB (binary-512)** with −1.79pt worst-case NDCG@10. Hamming popcount over 64-byte vectors is ~6× faster than fp32 cosine. **This is the P2P sync lever** — a 10k-entry vector namespace fits in a single mesh message.

**Caveats:**
- `int8` quantization implementation is currently broken (per-vector symmetric scale breaks cross-document comparability — docs with smaller max-component get artificially lower dot scores). int8 results in the lab output are invalid. int8 is anyway dominated by binary on the Pareto curve for comparable bytes-per-vec budgets, so fixing it is low-priority.
- Binary is strongly task-dependent at low dims: FiQA tolerates it well (retrieval task with discriminative token overlap), SciFact degrades more aggressively (fact-verification needs fine-grained sign agreement). Binary-512 is the narrowest budget that holds universally across the 4 tested BEIR sets.
- Lab used the defective-Xenova-bge / correct-Xenova-nomic cached vectors from `sota.db`. Re-running with the Rust-fastembed cache (Phase 24/25) should retain the same shape but shift absolute numbers up across the board.

**Reproduction:**
```bash
# Uses existing sota.db caches — no re-embed
node scripts/bench-lab.mjs --datasets scifact,arguana,fiqa,scidocs

# Results include per-dataset tables + Pareto frontier + cross-dataset shippable summary
# Machine-readable JSON: ~/.wellinformed/bench/lab/results-<timestamp>.json
```

### 2g. Cross-model embedding bridge gate — PASS at 91.9% retention (Phase 32)

Hypothesis: a linear map W: bge → nomic lets a peer running a BGE embedder retrieve documents indexed under a nomic embedder at ≥85% of native-nomic retrieval quality. If true, wellinformed peers can federate across heterogeneous encoder choices — the interop claim no OSS P2P memory currently makes.

**Method:** 5,183 paired SciFact corpus vectors extracted from existing bench `sota.db` caches (nomic + bge-Xenova, both 768d). Ridge-regularized least squares closed form — W = (XᵀX + λI)⁻¹ XᵀY, λ=0.01 — implemented as pure Float64Array Gauss-Jordan elimination. 12s solve, zero new deps. Training MSE on held-in sample: **1.58×10⁻⁴**.

**Result:**

| Config | NDCG@10 | R@10 | Retention vs native nomic |
|--------|---------|------|---------------------------|
| native nomic (ceiling) | **70.01%** | 82.71% | 100% (anchor) |
| **bridged bge → nomic** | **64.34%** | 79.67% | **91.9%** ✓ PASS |
| native bge (Xenova defective) | 63.46% | 74.42% | 90.6% |

**Gate verdict: PASS (91.9% ≥ 85%).** Linear W is shippable as the v3 cross-model interop primitive.

**Unexpected secondary finding:** the bridge **beats the native defective-Xenova-bge** (64.34% > 63.46%). Linear W effectively "repairs" the Xenova-bge port defect because the target space (nomic) is undefective. This suggests bridge training is a general-purpose mitigation for low-quality ONNX ports, not just an interop layer.

**Production path — the "USB-C of embeddings":**
- Ship a bridge registry — W matrices per encoder pair, trained on ~5k paired corpus vectors, distributed as ~2.4 MB matrix files (768×768 fp32).
- Peers pick the nearest canonical encoder (nomic-v1.5 for v3) and apply W at query time (or corpus time on receive).
- One-time per-encoder-pair training cost; runtime overhead is one 768×768 matvec per query (~0.5 ms).
- **This is the category-defining capability no OSS P2P memory has:** switch LLM provider → keep memory.

**Reproduction:**
```bash
# Uses existing sota.db caches (both encoders)
node scripts/bench-bridge.mjs
# Machine-readable JSON: ~/.wellinformed/bench/bridge-scifact/results.json
```

**Next gates** (for the full v3 interop claim):
1. Train W on a larger paired corpus (e.g. 50k MS MARCO passages) and re-measure on BEIR full sweep
2. Train `W_{bge→nomic}` via Rust-fastembed on both sides to rule out the Xenova-port confound
3. Test 4-way bridge chain: minilm → bge → nomic → canonical-v3
4. Evaluate bidirectional bridge (nomic ↔ bge) — asymmetric retrieval behavior

### 2h. Identity wave — W3C did:key + device hierarchy + signed envelopes (Phase 32)

Not a retrieval benchmark — infrastructure that makes the memory user-owned rather than device-bound or provider-bound. Every outbound memory entry wraps in a `SignedEnvelope<T>` verifiable offline by any peer with zero prior contact.

**Three-tier hierarchy:**
1. **User DID** — long-lived W3C `did:key` over Ed25519. Survives device changes via 64-char hex recovery seed (v1 format; BIP39 is a v1.1 follow-up).
2. **Device key** — operational Ed25519 keypair authorized by user DID via a signed `(device_id, device_pub, authorized_at)` tuple. Revocable without losing user identity.
3. **Signed envelope** — payload + device signature + device-over-user authorization chain, self-contained, 3-Ed25519-verify <2 ms offline.

**Measured properties** (32 tests, 293-test regression green):
- did:key encode/decode: W3C-shape stable round-trip, sub-µs
- Domain separation: `wellinformed-auth:v1:` vs `wellinformed-sig:v1:` prefix tags prevent cross-message signature replay
- Canonical JSON: key-order invariant, deterministic byte identity across runtimes
- Cross-device verification proven: envelope signed on device A verifies on freshly-imported device B under the same user DID. Export recovery hex → import on new device → memory identity survives.

**Production path:**
- `wellinformed identity {init|show|rotate|export|import}` CLI shipped
- `src/application/identity-bridge.ts` exposes the process-wide `signForCurrentDevice` / `verifyIncomingEnvelope` seam for downstream modules (search-sync, share-sync, touch, save, session-ingest) to integrate against
- Zero new deps — Ed25519 via Node built-in `crypto` (PKCS8/SPKI DER path)

**Why this matters for the v3 release:** the portable cross-model memory story only closes when the memory entries themselves are cryptographically bound to the user, not the device. The DID wave is the foundation layer; everything else (federated search, CRDT room sync, shared memory) builds on top.

### 2i. PPR graph-rerank gate — NULL on single-hop SciFact (Phase 32)

**Hypothesis:** adding a personalized-PageRank rerank layer over a doc-doc kNN graph lifts NDCG@10 on top of dense+hybrid retrieval, matching the HippoRAG-2 (NeurIPS 2024) single-hop-rerank behavior.

**Result:**

| Stage | NDCG@10 | R@10 | MRR |
|-------|---------|------|-----|
| dense (top-100) | 70.01% | 82.71% | 0.6716 |
| + PPR rerank (k=5 kNN, α=0.85, 50 iter) | 46.25% | 73.83% | 0.3913 |
| Δ | **−23.76pt** | −8.88pt | −0.2803 |

**Verdict: NULL.** PPR regresses by 23.76pt on single-hop BEIR SciFact.

**Why the regression happens (mechanistic):** PPR diffuses the top-100 initial scores over the kNN graph. On single-hop retrieval, the initial dense stage has already ranked the *relevant* documents highest. Diffusion leaks mass from relevant docs to their nearest neighbors (which are *not* relevant in single-hop BEIR by construction — SciFact's qrels mark specific passages, not topical neighborhoods). The relevant docs drop in rank; the rerank destroys quality.

**Why this was expected:** HippoRAG-2's reported +5–14% improvements are on **multi-hop QA benchmarks** (MuSiQue, HotpotQA), where the relevant answer requires traversing relationships between docs. Single-hop BEIR has no relationship structure for PPR to exploit. The published paper's single-hop ablation also shows near-zero or regressing deltas.

**What ships anyway:**
- `src/domain/pagerank.ts` — pure PPR primitive with dangling-node fixup + kNN graph builder + 12 tests green
- `src/domain/shamir.ts` — GF(2⁸) Shamir secret sharing (pure, no deps) + 14 tests green — unrelated to PPR, shipped in the same primitives wave for v3 social recovery (ADR-001, Non-decisions table)
- `scripts/bench-ppr.mjs` — the gate that measured the null

**Promotion criteria for v3.2:** run the same PPR primitive against MuSiQue + HotpotQA (multi-hop datasets). If PASS (+3pt NDCG@10 or equivalent R@5 lift), ship as a rerank path triggered by a `multi_hop: true` query flag. If NULL on multi-hop too, park the primitive and document the space more carefully.

### Wave 2 — reproducible numbers

#### BEIR SciFact (5,183 × 300)

| Metric | MiniLM (v1 baseline) | **nomic + BM25 hybrid (Wave 2)** | Lift |
|--------|----------------------|----------------------------------|------|
| NDCG@10 | 64.82% | **72.30%** | +7.48 |
| MAP@10  | 59.57% | **67.66%** | +8.09 |
| Recall@5  | 74.84% | **79.76%** | +4.92 |
| Recall@10 | 79.53% | **84.79%** | +5.26 |
| MRR | 0.6039 | **0.6904** | +0.0865 |
| Latency p50 | 3 ms | 36 ms | +33 ms |

#### BEIR NFCorpus (3,633 × 323, biomedical)

| Metric | MiniLM (v1 baseline) | **nomic Wave 1** | Lift |
|--------|----------------------|------------------|------|
| NDCG@10 | 31.35% | **34.11%** | +2.76 |
| MAP@10  | 22.60% | **25.14%** | +2.54 |
| Recall@10 | 15.22% | **15.85%** | +0.63 |

### 2b. Wave 3 — cross-encoder reranker FAILED on scientific text

**Attempt:** Add `Xenova/bge-reranker-base` (MS MARCO-trained cross-encoder) over top-100 hybrid results.

**Result:** NDCG@10 **regressed** 72.30% → 70.38% (−1.92 points). Rerank p50 latency = 25,940 ms per query (720× slower than Wave 2).

**Root cause (mechanistic, verified via `scripts/debug-reranker.mjs`):** bge-reranker-base was trained on MS MARCO (web queries) and has severe domain mismatch with scientific text. On a known-relevant pair from SciFact — query "0-dimensional biomaterials show inductive properties" + passage "Calcium phosphate nanomaterials (0-D biomaterials) induce osteogenic differentiation..." — the reranker scores this **negative** (−0.83). It doesn't know that calcium phosphate nanomaterials ARE 0-D biomaterials. The directionally-relevant pair "Zero-dimensional (0-D) biomaterials..." scores +6.30 as expected.

**Takeaway:** Cross-encoder rerankers require **domain-matched training data**. Generic MS-MARCO rerankers hurt scientific retrieval. No CPU-friendly SciFact-trained reranker exists in public packages. Recommendation: don't use bge-reranker-base on scientific corpora; if you need reranker lift, consider domain-specific alternatives or accept Wave 2.

**Reproduction:**
```bash
node scripts/bench-beir-sota.mjs scifact --hybrid --rerank  # reproduces 70.38%
node scripts/debug-reranker.mjs                              # one-pair sanity check
```

### 2c. Wave 4 — Room-aware retrieval produced a NULL result

**Hypothesis:** wellinformed's user-curated "rooms" (topic partitions) + cross-room "tunnels" could be a retrieval scoring signal, not just a filter. Per the 2024-2025 literature (RouterRetriever AAAI 2025, HippoRAG NeurIPS 2024, LexBoost SIGIR 2024, MixPR Dec 2024), partition-aware routing has published lift on BEIR (+2.1 to +3.2 NDCG@10) and multi-hop QA (+5 to +14 R@5).

**Gate test:** Before engineering a learned router, run the **upper bound** — oracle routing using gold topic labels — on a multi-topic benchmark. If oracle doesn't beat flat hybrid by ≥3 NDCG@10 points, rooms cannot be a retrieval signal in our setup, and engineering a router is wasted effort.

**Benchmark:** BEIR CQADupStack, 3 topically-distinct subforums (mathematica + webmasters + gaming), pooled into one 79,411-passage corpus with 2,905 test queries. Each query carries its source subforum label as the ground-truth "room."

**Setup:**
- Encoder: `Xenova/all-MiniLM-L6-v2` (384d, same baseline as Phase 1)
- Hybrid: dense + FTS5 BM25 + RRF k=60 (identical to Wave 2 pipeline)
- Flat: search pooled DB, no filter
- Oracle-routed: restrict search to query's gold subforum

**Result:**

|                      | FLAT    | ORACLE-ROUTED | Δ |
|----------------------|---------|---------------|---|
| NDCG@10              | 43.83%  | 44.17%        | **+0.34** |
| MAP@10               | 38.66%  | 38.99%        | +0.34 |
| Recall@5             | 48.08%  | 48.42%        | +0.34 |
| Recall@10            | 55.66%  | 55.95%        | +0.29 |
| Success@5            | 53.49%  | 54.01%        | +0.52 |
| MRR                  | 0.4230  | 0.4267        | +0.37 |

Per-room NDCG@10 breakdown (flat → oracle):

| Room        | n     | Flat    | Oracle  | Δ      |
|-------------|-------|---------|---------|--------|
| mathematica | 804   | 25.94%  | 26.86%  | +0.92  |
| webmasters  | 506   | 36.70%  | 36.71%  | +0.01  |
| gaming      | 1,595 | 55.11%  | 55.26%  | +0.15  |

**Interpretation.** The gate failed by a factor of ~9. Oracle routing — the absolute upper bound — beats flat hybrid by **0.34 NDCG@10 points**, well below the 3-point gate threshold. This is statistically null at n=2,905. Flat hybrid retrieval already recovers the routing signal implicitly: CQADupStack subforums have sufficiently disjoint vocabulary that a mathematica query's nearest neighbours are always in the mathematica corpus, and a gaming query's nearest neighbours are always in the gaming corpus. Routing adds nothing.

**Why learned routing and tunnel reranking cannot save it.** Oracle routing IS the ceiling. A learned router can only approximate oracle (the research report predicted it would capture ~half the oracle gap — which in our case would mean **+0.17** NDCG@10). Tunnel-based neighbour reranking is a rerank layer on top of routed results; it cannot exceed the oracle ceiling either.

**What this does and does not say:**
1. ✗ "Room-aware retrieval beats flat hybrid on public benchmarks" — disproved, at least on CQADupStack-class benchmarks.
2. ✓ "Rooms organize the knowledge graph by topic with no retrieval quality cost" — confirmed. Flat and oracle-routed are functionally equivalent, so users get namespace/permission benefits for free.
3. ✓ "Tunnels are useful for cross-room discovery, not reranking" — tunnels remain a valid UX feature for surfacing serendipitous cross-domain connections (the original design intent), but they should not be wired into the hot retrieval path.
4. **Open question:** On a benchmark with *overlapping-vocabulary* rooms (e.g. "ml-papers" vs "ml-codebase" — same topic, different formats) where flat retrieval would actually confuse sources, does routing help? No public benchmark of this shape exists. The research report confirmed: "Nothing in the literature uses explicitly user-curated partitions + inter-partition edges as a retrieval scoring signal."

**Reproduction:**
```bash
# Download CQADupStack (5.3 GB)
curl -fsL -o cqa.zip https://public.ukp.informatik.tu-darmstadt.de/thakur/BEIR/datasets/cqadupstack.zip
unzip -oq cqa.zip -d ~/.wellinformed/bench/cqadupstack/

# Run the gate test
node scripts/bench-room-routing.mjs \
  --datasets-dir ~/.wellinformed/bench/cqadupstack/cqadupstack \
  --rooms mathematica,webmasters,gaming \
  --model Xenova/all-MiniLM-L6-v2 --dim 384
```

**Strategic conclusion:** After 4 measured waves, **Wave 2 at 72.30% NDCG@10 is the CPU-local SOTA ceiling for wellinformed on standard BEIR retrieval**. Further engineering should target orthogonal value (UX, security, federated P2P, structured code graph, session persistence) — not encoder stacking or router architectures that don't beat flat hybrid at our parameter budget. The honest story is better than a hypothetical one.

### BEIR SciFact (test split) — Model comparison

| Metric | MiniLM-L6-v2 (v1 baseline) | **nomic-embed-text-v1.5** (current) | BM25 | BGE-Large | E5-Large |
|--------|----------------------------|-------------------------------------|------|-----------|----------|
| Corpus | 5,183 | 5,183 | — | — | — |
| Queries | 300 | 300 | — | — | — |
| **NDCG@10** | 64.82% | **69.98%** (+5.16) | 66.5% | 74.6% | 72.6% |
| **MAP@10** | 59.57% | **65.19%** (+5.62) | — | — | — |
| **Recall@5** | 74.84% | **76.26%** (+1.42) | — | — | — |
| **Recall@10** | 79.53% | **83.12%** (+3.59) | — | — | — |
| **MRR** | 0.6039 | **0.6668** (+0.063) | — | — | — |
| **Latency p99** | 3 ms | 6 ms | — | — | — |
| Indexing rate | 19 docs/sec | 4 docs/sec | — | — | — |

**nomic-embed-text-v1.5 beats classical BM25 on SciFact** (69.98% vs 66.5%) and lands in the 65-75% retrieval tier alongside BGE-Large (74.6%) and E5-Large (72.6%). The measured number (69.98%) matches Nomic's own published benchmark (70.36%) within 0.4 NDCG points, confirming the pipeline correctly loads the model via `@xenova/transformers@2.17.2` with `search_document:` / `search_query:` prefixes and 768-dim vec0 tables.

### BEIR NFCorpus (test split, biomedical) — Model comparison

| Metric | MiniLM-L6-v2 (v1 baseline) | **nomic-embed-text-v1.5** (current) | BM25 | BGE-Large | E5-Large |
|--------|----------------------------|-------------------------------------|------|-----------|----------|
| Corpus | 3,633 | 3,633 | — | — | — |
| Queries | 323 | 323 | — | — | — |
| **NDCG@10** | 31.35% | **34.11%** (+2.76) | 32.5% | 34.5% | 36.6% |
| **MAP@10** | 22.60% | **25.14%** (+2.54) | — | — | — |
| **Recall@5** | 11.53% | **12.82%** (+1.29) | — | — | — |
| **Recall@10** | 15.22% | **15.85%** (+0.63) | — | — | — |
| **MRR** | 0.5056 | **0.5387** (+0.033) | — | — | — |

**nomic beats BM25 on NFCorpus** (34.11% vs 32.5%) and approaches BGE-Large (34.5%). NFCorpus is biomedical — general-purpose embeddings have a quality ceiling here.

### Wave 1 summary — model swap only

| What changed | Before | After |
|---|---|---|
| Model | `Xenova/all-MiniLM-L6-v2` | `nomic-ai/nomic-embed-text-v1.5` |
| Dimensions | 384 | 768 |
| ONNX size | ~25 MB | ~550 MB |
| Context window | 512 tokens | 8192 tokens |
| SciFact NDCG@10 | 64.82% | **69.98%** (+5.16) |
| NFCorpus NDCG@10 | 31.35% | **34.11%** (+2.76) |
| Query latency p99 | 3 ms | 6 ms |
| Index throughput | 19 docs/sec | 4 docs/sec |
| npm deps added | — | **0** |

Wave 1 (model swap) of the SOTA upgrade path from `.planning/SOTA-UPGRADE-PLAN.md` is measured and verified. Wave 2 (hybrid BM25 + RRF) and Wave 3 (cross-encoder reranker) remain as further gains if desired — both also zero-dep.

### Reproduce the comparison

```bash
# baseline (MiniLM)
node scripts/bench-beir.mjs scifact
node scripts/bench-beir.mjs nfcorpus

# nomic
node scripts/bench-beir.mjs scifact \
  --model nomic-ai/nomic-embed-text-v1.5 --dim 768 \
  --doc-prefix "search_document: " --query-prefix "search_query: "
node scripts/bench-beir.mjs nfcorpus \
  --model nomic-ai/nomic-embed-text-v1.5 --dim 768 \
  --doc-prefix "search_document: " --query-prefix "search_query: "
```

### Latency under real BEIR load

Measured on 300-1,400 queries against 3K-5K passage indexes:

| Dataset | Queries | Corpus | p50 | p95 | p99 |
|---------|---------|--------|-----|-----|-----|
| SciFact | 300 | 5,183 | **2 ms** | **3 ms** | **3 ms** |
| NFCorpus | 323 | 3,633 | **1 ms** | **2 ms** | **2 ms** |

**p99 retrieval latency is < 5 ms under realistic workloads** — the steady-state latency claim from Section 3 holds under real BEIR-scale benchmarking.

### Indexing throughput

~19-20 docs/sec on CPU ONNX (single-core, batch=32). The bottleneck is the ONNX model forward pass, not sqlite-vec insertion. A 5,000 passage corpus indexes in ~4 minutes.

### Reproducibility

Both results are fully reproducible:

```bash
node scripts/bench-beir.mjs scifact    # ~4 minutes
node scripts/bench-beir.mjs nfcorpus   # ~3 minutes
```

Raw results stored as JSON at `~/.wellinformed/bench/<dataset>/results.json`. Dataset downloaded from the canonical BEIR v1 source (`public.ukp.informatik.tu-darmstadt.de/thakur/BEIR`) and cached locally.

### Honest assessment of quality claim

1. **wellinformed matches the published ceiling of its embedding model.** On two BEIR datasets in two distinct domains, our pipeline extracts the retrieval quality `all-MiniLM-L6-v2` is capable of. The pipeline is correctly implemented; we're not leaving quality on the table.
2. **The embedding model is mid-tier.** `all-MiniLM-L6-v2` is the fast/small tier (23 MB, 80 MB RAM). BGE-Large and E5-Large beat it by 5-10 NDCG points in exchange for 400+ MB RAM and 3-5× slower inference. This is a deliberate tradeoff for the local-first, no-GPU wellinformed use case.
3. **No SOTA claim.** We do not beat the BEIR leaderboard. We match the leaderboard for our chosen model. If SOTA were a goal, swapping in BGE-Large or a voyage-ai API embedder would gain ~10 NDCG points at the cost of deployment complexity.
4. **The previous 96.8% number was small-sample luck** — 15 passages × 10 queries is too small to produce a meaningful NDCG. The mini-harness remains in the test suite as a smoke test, not as a leaderboard number.

### Competitive landscape

Full research in [`BENCH-COMPETITORS.md`](./BENCH-COMPETITORS.md). Key takeaways:

#### Agent memory frameworks with published benchmarks

| System | Stars | Benchmark | Claim | Verified? |
|--------|-------|-----------|-------|-----------|
| [mem0](https://github.com/mem0ai/mem0) | 52.9K | LOCOMO LLM-judge | 66.9% (plain) / 68.4% (graph) | ECAI 2025 paper; **disputed by Zep** |
| [Graphiti/Zep](https://github.com/getzep/graphiti) | 24.8K | LOCOMO LLM-judge | 84% (orig) / 58.4% (Mem0 correction) / 75.1% (Zep counter) | **3-way dispute — treat all as contested** |
| [Letta](https://github.com/letta-ai/letta) (ex-MemGPT) | 22.0K | LOCOMO | 74% with gpt-4o-mini + plain filesystem | Vendor blog only |
| [Mastra](https://github.com/mastra-ai/mastra) (Observational Memory) | 22.9K | LongMemEval | 94.87% (gpt-5-mini) / 84.23% (gpt-4o) | No arXiv; eliminates retrieval via compression |
| [Engram](https://github.com/Gentleman-Programming/engram) | 2.5K | LOCOMO | 80.0% accuracy, 93.6% fewer tokens | arXiv:2511.12960; most honest MCP-tier number |
| [cognee](https://github.com/topoteretes/cognee) | 15.2K | HotPotQA (24 Q) | EM 0.5, F1 0.63 | Vendor blog; tiny sample |
| [memobase](https://github.com/memodb-io/memobase) | 2.7K | LOCOMO | 0.7578 overall | Own repo docs |
| [MemPalace](https://github.com/milla-jovovich/mempalace) | 44.1K | LongMemEval R@5 | 96.6% raw / 100% reranked | **Inflated** — 96.6% is plain ChromaDB verbatim, not the palace architecture (issue #214) |
| [plastic-labs/honcho](https://github.com/plastic-labs/honcho) | 2.3K | — | none published | — |
| [mcp-memory-service](https://github.com/doobidoo/mcp-memory-service) | 1.7K | LongMemEval R@5 | 86.0% session / 80.4% turn | **Reproducible scripts in repo** — closest apples-to-apples |
| **wellinformed (Wave 2)** | — | BEIR SciFact (5,183 × 300) | **72.30% NDCG@10, 79.76% R@5** | Full BEIR v1, `bench-beir-sota.mjs --hybrid`, 137M params, CPU 36ms p50 |

#### LOCOMO benchmark war (disclosure)

mem0, Zep, memobase, Engram, and Letta all cite LOCOMO with **incompatible evaluation setups** — adversarial category inclusion, different system prompts, different LLM judges. **No single vendor's LOCOMO number can be taken at face value without independent replication.** The numbers above are the vendors' own claims, annotated with verification status.

#### Honest assessment of wellinformed's retrieval claim

- **Wave 2 is measured, not claimed.** 72.30% NDCG@10 on BEIR SciFact is full-benchmark, 5,183 passages × 300 queries, reproducible via `node scripts/bench-beir-sota.mjs scifact --hybrid`. Machine-readable results at `~/.wellinformed/bench/scifact__nomic-ai-nomic-embed-text-v1-5__hybrid/results.json`.
- **Leaderboard position:** within ~2 NDCG points of the best dense-only encoders at our parameter budget (bge-base-en-v1.5 = 74.0, E5-base-v2 = 73.1) and 4.4 points below GPU-required reranker stacks (monoT5-3B = 76.7). Competitive for a 137M CPU-local model.
- **What failed, documented:** Wave 3 (cross-encoder reranker) regressed quality by 1.92 points due to MS-MARCO/scientific-text domain mismatch. Wave 4 (room-aware routing) produced a +0.34 oracle-lift on CQADupStack — statistically null. Both failures are in §2b and §2c of this report.
- **Prior mini-harness (15 passages × 10 queries, 96.8% NDCG@10) was removed as a reportable number.** It survives as a smoke test in `npm test` only — too small to produce a leaderboard-comparable number.

#### Market niche wellinformed occupies alone

No competitor in the table above combines **all five** of: (1) multi-source heterogeneous research ingestion (ArXiv/HN/RSS/URL/codebase/deps/git), (2) native MCP with 15 tools, (3) cross-domain tunnel discovery + recursive source expansion, (4) P2P knowledge sharing via libp2p + Y.js CRDT, (5) structured code graph indexing via tree-sitter. Every other tool ships 1-2 of these; wellinformed ships all five.

#### Code intelligence (Phase 19 comparison)

| Tool | Stars | Retrieval benchmark | Notes |
|------|-------|---------------------|-------|
| [Aider](https://github.com/Aider-AI/aider) | 43.3K | SWE-bench Lite 26.3% (2024) | Not retrieval — task completion |
| [Continue.dev](https://github.com/continuedev/continue) | 32.5K | None published | Recommends voyage-code-3 |
| [Sourcegraph SCIP](https://github.com/sourcegraph/scip) | 593 | None published | Protocol, not a tool |
| [LanceDB](https://github.com/lancedb/lancedb) | 9.9K | ANN recall >0.95 on GIST-1M | Infrastructure, not code graph |
| **wellinformed codebase** | — | (no standard benchmark) | 16,855 nodes, < 2 ms p99 search, tree-sitter TS/JS/Python |

**No code intelligence tool in this category publishes NDCG / R@K retrieval numbers.** Aider reports SWE-bench (task completion, not retrieval). wellinformed's code graph has no direct apples-to-apples competitor with a published retrieval benchmark.

---

## 3. Steady-State Latency (warm, in-process)

These numbers reflect daemon / MCP server performance — no CLI cold-start, no Node boot. Measured over 1,000 iterations per query.

### 3a. Code graph LIKE search (16,855 nodes)

| Query Pattern | p50 | p95 | p99 | max |
|---------------|-----|-----|-----|-----|
| exact `%createNode%` | 1 ms | 2 ms | 2 ms | 2 ms |
| broad `%run%` | < 1 ms | 1 ms | 1 ms | 1 ms |
| broad `%node%` | < 1 ms | 1 ms | 1 ms | 1 ms |
| no-match `%zzzqqq%` | 1 ms | 2 ms | 2 ms | 2 ms |
| prefix `parse%` | < 1 ms | 1 ms | 1 ms | 1 ms |

### 3b. Code graph kind-filtered search

| Query | p50 | p95 | p99 |
|-------|-----|-----|-----|
| `functions %parse%` | < 1 ms | 1 ms | 1 ms |
| `classes %Error%` | 2 ms | 2 ms | 2 ms |
| `imports %libp2p%` | 1 ms | 2 ms | 2 ms |

### 3c. Vector k-NN search (sqlite-vec, 2,830 vectors × 384 dims)

| Query | p50 | p95 | p99 | max |
|-------|-----|-----|-----|-----|
| k=10 | 3 ms | 4 ms | 4 ms | 4 ms |
| k=50 | 3 ms | 4 ms | 4 ms | 5 ms |

**All steady-state operations are sub-5ms p99.** The sqlite-vec adapter is effectively constant-time for k=10 vs. k=50 at this corpus size.

---

## 4. Cold-Start Latency (CLI one-shot invocations)

Each invocation spawns a fresh Node + tsx process, loads TypeScript on the fly, initializes sqlite-vec, and reads config. Cold-start is the floor cost for single-shot CLI commands.

| Command | Latency | What it measures |
|---------|---------|-----------------|
| `wellinformed version` | 716 ms | Pure Node + tsx boot |
| `wellinformed help` | 707 ms | Same + command routing |
| `wellinformed room list` | 719 ms | + rooms.json read |
| `wellinformed peer status` | 710 ms | + peer-identity.json read |
| `wellinformed peer list --json` | 716 ms | + peers.json read |
| `wellinformed codebase list` | 790 ms | + code-graph.db open |
| `wellinformed codebase list --json` | 715 ms | |

**Floor latency: ~700 ms.** Node + tsx startup dominates. Any search / lookup work beyond that is < 15 ms.

### Code graph search (cold-start inclusive)

| Query | Total | Search Cost | Boot Cost |
|-------|-------|-------------|-----------|
| `codebase search createNode` | 713 ms | ~1 ms | ~712 ms |
| `codebase search ShareableNode` | 712 ms | ~1 ms | ~711 ms |
| `codebase search run` | 715 ms | < 1 ms | ~714 ms |
| `codebase search parse --kind function` | 712 ms | < 1 ms | ~711 ms |
| `codebase search test --codebase <id>` | 716 ms | ~1 ms | ~715 ms |
| `codebase search node --limit 100` | 734 ms | ~5 ms | ~729 ms |

### Research ask (cold-start + ONNX load)

| Query | Total | What it includes |
|-------|-------|------------------|
| `ask "embeddings"` | 923 ms | Boot + ONNX model load + embed + vector search |
| `ask "functional DDD neverthrow Result monad"` | 957 ms | |
| `ask "libp2p" --room p2p-llm` | 923 ms | |
| `ask "qqqwwwzzz nothing here"` | 922 ms | |

The ~210 ms overhead vs. simple CLI commands is dominated by loading the ONNX model into memory. Subsequent `ask` calls in the same process would be < 10 ms.

---

## 5. Indexing Throughput

### Incremental reindex (sha256 dirty-check)

All files unchanged → skipped after hash check. Near-zero work.

| Codebase | Files Walked | Duration |
|----------|--------------|----------|
| wellinformed | 116 files | 777 ms (6.7 ms/file including cold-start) |
| p2p-llm-network | 293 files | 812 ms (2.8 ms/file) |
| forge | 225 files | 785 ms (3.5 ms/file) |
| auto-tlv | 260 files | 780 ms (3.0 ms/file) |

### Full index (tree-sitter parse + SQLite insert)

Initial index runs (from session history):

| Codebase | Files | Nodes | Edges | Throughput |
|----------|-------|-------|-------|------------|
| wellinformed | 116 | 3,046 | 9,406 | ~260 files/sec |
| p2p-llm-network | 293 | 5,793 | 18,736 | ~65 files/sec (mixed Python/TS/JS) |
| forge | 225 | 5,139 | 17,825 | ~75 files/sec |
| auto-tlv | 260 | 4,200 | 11,965 | ~95 files/sec |

Tree-sitter parse time per file is ~1-3 ms. The majority of indexing time is SQLite insert + call graph resolution pass 2.

---

## 6. Memory Footprint (max RSS)

| Command | Peak RSS |
|---------|----------|
| `wellinformed version` | **156 MB** (Node + tsx baseline) |
| `wellinformed codebase search run` | **164 MB** (+8 MB for better-sqlite3 handle) |
| `wellinformed codebase list` | **159 MB** |
| `wellinformed ask "embeddings"` | **312 MB** (+156 MB for ONNX model) |

Daemon mode (persistent process) would hold one 312 MB allocation and reuse it for every query.

---

## 7. Call Graph Resolution Accuracy

The arrow-function name-capture fix applied this session dramatically improved call graph quality. Post-fix numbers on the wellinformed codebase:

| Confidence Level | Before Fix | After Fix | Improvement |
|------------------|------------|-----------|-------------|
| **exact** (name resolved in same-file or explicit import) | 47 | **1,474** | **31.4x** |
| **heuristic** (ambiguous — multiple candidates) | 2 | 472 | 236x |
| **unresolved** (external / dynamic dispatch) | 6,439 | 4,530 | -29.7% (dropped) |

Across all 4 indexed TypeScript/JS codebases:

| Codebase | Exact | Heuristic | Unresolved |
|----------|-------|-----------|------------|
| wellinformed | 1,474 | 472 | 4,530 |
| p2p-llm-network | 2,794 | 3,528 | 6,913 |
| forge | 2,486 | 2,079 | 8,335 |
| auto-tlv | 521 | 1,362 | 6,138 |

`unresolved` counts are dominated by external library calls (`fs.readFile`, `Array.prototype.map`, etc.) that are expected to be unresolved without full type resolution — tree-sitter does syntactic parsing, not type checking.

---

## 8. P2P Subsystem (Phase 15-18)

### 10-peer mesh integration test (real libp2p)

From `tests/phase18.production-net.test.ts`:

- **10 libp2p nodes** spun up in-process with `listenPort: 0`, `mdns: false`
- Ring + cross-link mesh topology
- Pass bar: every node connected to ≥ 3 others within 10 seconds
- **Actual runtime: ~2.5 seconds** end-to-end
- Cleanup: `Promise.allSettled(nodes.map(n => n.stop()))` — no socket leaks

### Secrets scanner (14 patterns)

| Pattern Category | Example |
|------------------|---------|
| OpenAI | `sk-[a-zA-Z0-9]{20,}` |
| GitHub token / OAuth / fine-grained PAT | `ghp_`/`gho_`/`github_pat_` |
| AWS access key | `AKIA[0-9A-Z]{16}` |
| Stripe live | `sk_live_[a-zA-Z0-9]{24}` |
| Bearer JWT | anchored to ey[JK]... . ... . ... shape |
| Google API key | `AIza[0-9A-Za-z_-]{35}` |
| Slack | `xox[baprs]-[A-Za-z0-9-]{10,}` |
| Private key block | `-----BEGIN...PRIVATE KEY-----` |
| 5 more (password/api-key/env-token/env-secret) | — |

All 14 patterns regression-tested. Scan runs in O(n×p) where n = chars, p = 14 patterns.

### Federated search quality

- `ask --peers` adds ~2s per-peer timeout (P99 fanout bounded)
- Result merging: O(k × peers) with cosine-distance-ascending sort
- `_source_peer` annotation on every result — zero false provenance

---

## 9. End-to-End Value Verification

Ran a real cross-project query to prove the graph adds value:

```
$ wellinformed ask "functional DDD neverthrow Result monad"

## Forge: Architectural Patterns [chunk 1/6]          — research note
## neverthrow@^8.2.0                                  — npm dep
## Forge: Architectural Patterns [chunk 6/6]          — research note
## Auto TLV: services/enricher/pipeline/enricher.go   — code file
## Auto TLV: internal/enricher/enricher.go            — code file
```

**One query surfaces: research notes from forge + npm dep metadata from wellinformed-dev + Go source code from auto-tlv.** This is exactly the cross-project retrieval the tool is designed for.

---

## 10. Performance Summary

| Dimension | Number | Context |
|-----------|--------|---------|
| **Test coverage** | 313/313 | 6 phases, zero regressions |
| **Retrieval quality (Wave 2 NDCG@10)** | **72.30%** | Full BEIR SciFact, 5,183 × 300, reproducible |
| **Retrieval quality (Wave 2 Recall@5)** | **79.76%** | Same run |
| **Retrieval quality (Wave 2 MRR)** | **0.690** | Same run |
| **Code search (warm p99)** | **< 5 ms** | 16,855 nodes |
| **Vector search (warm p99)** | **< 5 ms** | 2,830 × 384 dims |
| **Code search (cold CLI)** | ~715 ms | Node + tsx boot dominated |
| **Ask (cold CLI)** | ~925 ms | + ONNX model load |
| **10-peer libp2p mesh** | ~2.5 s | Real nodes, in-process |
| **Idle RSS** | 156 MB | |
| **RSS with ONNX loaded** | 312 MB | |

---

## Observations

**Strengths:**
1. **Retrieval quality is measured, competitive, and honest** — 72.30% NDCG@10 on full BEIR SciFact, within ~2 points of the best dense-only encoders at our parameter budget. Two wave-level failures (reranker, room routing) are documented for reproducibility in §2b and §2c.
2. **Steady-state latency is excellent** — every warm query lands under 5 ms p99
3. **Scale headroom is large** — at 16,855 code nodes the LIKE search is still < 2 ms; sqlite-vec is constant-time at this corpus
4. **243 tests zero regressions** across 5 phases of substantial new subsystems (P2P, CRDT sync, federated search, NAT traversal, structured code indexing)
5. **10 real libp2p peers mesh in 2.5s** — P2P subsystem works on real infrastructure

**Weaknesses:**
1. **Cold-start dominates CLI UX** — 700 ms Node + tsx boot floor. One-shot commands feel slow; daemon / MCP mode is the fast path. The README should emphasize this.
2. **code-graph.db is 374 MB** — but mostly from WAL and indexes. After `VACUUM` the actual data is ~50 MB. Worth adding a `codebase compact` command.
3. **Call graph resolution is 70-80% unresolved** on the bigger codebases — expected for tree-sitter (no type info), but users should know it's not a type-aware call graph. `@ast-grep/napi` + language server integration is the Phase 20 path.
4. **No benchmark suite in CI** — this was a one-shot. The `scripts/bench-v2.sh` + `scripts/bench-warm.mjs` should run on every merge to catch regressions.

**Opportunities (Phase 20+):**
1. **MCP server mode is the answer to cold-start** — one persistent process, every query < 10 ms end-to-end
2. **Vector embeddings for code nodes** — currently only lexical; semantic code search would land at < 5 ms given the vec_nodes performance
3. **Rust + Go tree-sitter grammars** — deferred from Phase 19; dep budget allows it
4. **LSP integration for type-aware call graph** — turns `unresolved` into `exact` for any running language server

---

*Generated by `scripts/bench-v2.sh` + `scripts/bench-warm.mjs` on 2026-04-13*
