# Roadmap: wellinformed v1.0

**Milestone:** v1.0 Ship-Ready
**Phases:** 7-10 (continues from v0.x which ended at Phase 6)
**Requirements:** 29 mapped

## Phase 7: Telegram Bridge

**Goal:** Users can forward links to a Telegram bot for ingestion, receive daily digests, and query the graph from their phone.

**Requirements:** TELE-01, TELE-02, TELE-03, TELE-04, TELE-05, TELE-06

**Success criteria:**
1. Forwarding a URL to the bot creates a new node in the correct room within 30 seconds
2. Daily digest message arrives after daemon tick with top-3 new items per room
3. Sending "ask embeddings" to the bot returns search results formatted for mobile
4. Bot token + chat_id configured via config.yaml, validated by `wellinformed doctor`

**Deliverables:**
- `src/telegram/bot.ts` — Telegram Bot API client (long-polling)
- `src/telegram/capture.ts` — URL → room classification → ingest
- `src/telegram/digest.ts` — Post-tick summary formatting + send
- `src/telegram/commands.ts` — Inbound command routing (ask, report, trigger, status, rooms)
- `src/cli/commands/telegram.ts` — setup / test / capture-start
- `tests/phase7.telegram.test.ts`

## Phase 8: Source Adapters Expansion

**Goal:** 10 new source adapters covering Reddit, Dev.to, Product Hunt, Ecosyste.ms, GitHub Releases, npm trending, Twitter/X, YouTube transcripts, podcasts. All wired into the discovery loop.

**Requirements:** ADPT-01 through ADPT-10

**Success criteria:**
1. `wellinformed discover --room homelab` suggests Reddit, Dev.to, and other new adapters based on keywords
2. `wellinformed trigger` fetches from at least 5 new adapter types without errors
3. Each new adapter has at least one test verifying fetch + parse + ContentItem output
4. Discovery loop's KNOWN_CHANNELS includes all 10 new adapter types

**Deliverables:**
- `src/infrastructure/sources/reddit.ts`
- `src/infrastructure/sources/devto.ts`
- `src/infrastructure/sources/product-hunt.ts`
- `src/infrastructure/sources/ecosystems-timeline.ts`
- `src/infrastructure/sources/github-releases.ts`
- `src/infrastructure/sources/npm-trending.ts`
- `src/infrastructure/sources/twitter-search.ts`
- `src/infrastructure/sources/youtube-transcript.ts`
- `src/infrastructure/sources/podcast-rss.ts`
- Updated `src/application/discover.ts` with KNOWN_CHANNELS entries
- `tests/phase8.adapters.test.ts`

## Phase 9: Visualization & Export

**Goal:** Interactive HTML graph visualization via graphify's Python sidecar with Leiden clustering, Obsidian vault export, and production multi-room tunnel detection.

**Requirements:** VIZ-01 through VIZ-06

**Success criteria:**
1. `wellinformed viz` generates an interactive HTML file viewable in a browser with community-colored nodes
2. Nodes are clickable and link to their source_uri
3. `wellinformed export obsidian --room homelab` produces a vault with one .md file per node and backlinks for edges
4. Running with 2 rooms shows at least one tunnel candidate in the report

**Deliverables:**
- `src/cli/commands/viz.ts` — shells out to graphify's Python export.to_html
- `src/cli/commands/export-obsidian.ts` — generates Obsidian vault
- `src/infrastructure/graphify-sidecar.ts` — Python sidecar wrapper for cluster + export
- `tests/phase9.viz.test.ts`

## Phase 10: Distribution & CI/CD

**Goal:** wellinformed is installable from npm, has CI/CD, and ships a Docker image. Users go from zero to running in one command.

**Requirements:** DIST-01 through DIST-07

**Success criteria:**
1. `npx wellinformed doctor` works on a clean machine with Node 20+ and Python 3.10+
2. `npm i -g wellinformed && wellinformed init` works end-to-end
3. GitHub Actions runs tests on every push and PR, blocks merge on failure
4. `git tag v1.0.0 && git push --tags` triggers npm publish + Docker build
5. `docker run saharbarak/wellinformed daemon start` runs the daemon in a container
6. README shows npm/npx as primary install path

**Deliverables:**
- `.github/workflows/ci.yml` — test + build on push/PR
- `.github/workflows/release.yml` — npm publish + Docker build on tag
- `Dockerfile` — multi-stage build (Node + Python + graphify)
- Updated `package.json` (prepublish script, files list, bin entry)
- Updated `README.md` install section

## Phase Summary

| Phase | Name | Requirements | Success Criteria |
|-------|------|-------------|------------------|
| 7 | Telegram Bridge | TELE-01..06 (6) | 4 |
| 8 | Adapter Expansion | ADPT-01..10 (10) | 4 |
| 9 | Visualization & Export | VIZ-01..06 (6) | 4 |
| 10 | Distribution & CI/CD | DIST-01..07 (7) | 6 |
| **Total** | | **29** | **18** |

---
*Roadmap created: 2026-04-12*
*Last updated: 2026-04-12 after initial creation*
