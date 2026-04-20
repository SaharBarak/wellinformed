# wellinformed CLI demo — the P2P knowledge network
# Recorded via VHS https://github.com/charmbracelet/vhs
#
# Narrative (5 beats, ~45 s):
#   1. Who am I            peer status       — did:key + libp2p identity
#   2. What do I know      room list         — 11 rooms, rich keyword index
#   3. Ask local           ask <query>       — cross-source (GitHub + code + docs)
#   4. Ask the network     ask --peers       — federated over libp2p
#   5. Wire Claude Code    claude install    — one line, done

Output docs/demo.gif

Set Shell "zsh"
Set FontSize 13
Set Width 1000
Set Height 620
Set TypingSpeed 28ms
Set PlaybackSpeed 1.0
Set Theme "Catppuccin Mocha"
Set Padding 18
Set Margin 0
Set BorderRadius 10
Set WindowBar Colorful
Set WindowBarSize 30

# ─── hidden setup — make zsh treat `# ...` lines as comments ─
# Without this, the narrative `# beat` lines below trigger
# "zsh: command not found: #" on each Enter.
Hide
Type "setopt interactive_comments"
Enter
Type "clear"
Enter
Sleep 300ms
Show

# ─── Beat 1 — peer identity (did:key + libp2p) ─────────────────
Type "# who am i — did:key + libp2p peer"
Sleep 600ms
Enter
Type "wellinformed peer status"
Sleep 250ms
Enter
Sleep 1800ms

# ─── Beat 2 — graph breadth, 11 rooms ──────────────────────────
Type@25ms "# what do i know — 11 rooms, 4865 nodes"
Sleep 500ms
Enter
Type "wellinformed room list | head -6"
Sleep 250ms
Enter
Sleep 2800ms

# ─── Beat 3 — cross-source ask (GitHub repo + your code + docs) ─
Type@25ms "# ask across everything — github, local code, research"
Sleep 500ms
Enter
Type@35ms `wellinformed ask "vector search sqlite" --k 3`
Sleep 250ms
Enter
Sleep 3200ms

# ─── Beat 4 — federated ask over libp2p ────────────────────────
Type@25ms "# ask the network — federated over libp2p"
Sleep 500ms
Enter
Type@35ms `wellinformed ask "P2P knowledge graph" --k 3 --peers`
Sleep 250ms
Enter
Sleep 3000ms

# ─── Beat 5 — wire into Claude Code (MCP) ──────────────────────
Type@25ms "# wire into claude code (one line)"
Sleep 500ms
Enter
Type "claude mcp add --scope user wellinformed -- wellinformed mcp"
Sleep 250ms
Enter
Sleep 1600ms

Sleep 1500ms
