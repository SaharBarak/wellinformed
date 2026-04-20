# wellinformed CLI demo — the P2P knowledge network
# Recorded via VHS https://github.com/charmbracelet/vhs
#
# Narrative (5 beats, tight ~30 s):
#   1. peer identity          did:key + libp2p PeerId
#   2. known peers            the network has neighbors
#   3. ask the graph          cross-source (GitHub + code + notes)
#   4. ask the network        federated over libp2p
#   5. wire Claude Code       one-line MCP registration
#
# Each beat clears the screen first so every frame is crisp.

Output docs/demo.gif

Set Shell "zsh"
Set FontSize 13
Set Width 1000
Set Height 620
Set TypingSpeed 22ms
Set PlaybackSpeed 1.0
Set Theme "Catppuccin Mocha"
Set Padding 20
Set Margin 0
Set BorderRadius 10
Set WindowBar Colorful
Set WindowBarSize 30

# ─── hidden setup — interactive_comments + clean slate ─
Hide
Type "setopt interactive_comments"
Enter
Type "clear"
Enter
Sleep 200ms
Show

# ─── Beat 1 — identity (did:key + libp2p PeerId) ───────────────
Type "wellinformed peer status"
Sleep 200ms
Enter
Sleep 1800ms

Hide
Type "clear"
Enter
Show

# ─── Beat 2 — known peers (the federation has neighbors) ───────
Type "wellinformed peer list"
Sleep 200ms
Enter
Sleep 1800ms

Hide
Type "clear"
Enter
Show

# ─── Beat 3 — cross-source ask ─────────────────────────────────
Type@30ms `wellinformed ask "vector search sqlite" --k 3`
Sleep 200ms
Enter
Sleep 2500ms

Hide
Type "clear"
Enter
Show

# ─── Beat 4 — federated ask over libp2p ────────────────────────
Type@30ms `wellinformed ask "P2P knowledge graph" --k 3 --peers`
Sleep 200ms
Enter
Sleep 2500ms

Hide
Type "clear"
Enter
Show

# ─── Beat 5 — wire into Claude Code (MCP) ──────────────────────
Type "claude mcp add --scope user wellinformed -- wellinformed mcp"
Sleep 200ms
Enter
Sleep 1800ms

Sleep 1200ms
