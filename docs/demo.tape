# wellinformed CLI demo — recorded via VHS
# See: https://github.com/charmbracelet/vhs

Output docs/demo.gif

Set Shell "zsh"
Set FontSize 13
Set Width 960
Set Height 580
Set TypingSpeed 40ms
Set PlaybackSpeed 1.0
Set Theme "Catppuccin Mocha"
Set Padding 18
Set Margin 0
Set BorderRadius 8
Set WindowBar Colorful
Set WindowBarSize 28

# Show version
Type "wellinformed version"
Sleep 300ms
Enter
Sleep 1500ms

# Show commands
Type "wellinformed help | head -20"
Sleep 300ms
Enter
Sleep 2500ms

# Run a semantic query — the primary agent integration
Type@60ms `wellinformed ask "vector search sqlite" --k 3`
Sleep 300ms
Enter
Sleep 4500ms

# Show the graph report
Type "wellinformed report --room auto-tlv 2>/dev/null | head -8"
Sleep 300ms
Enter
Sleep 3000ms

# Graceful pause on the result
Sleep 2000ms
