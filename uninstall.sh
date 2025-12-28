#!/bin/bash
# Claude Minions Uninstaller
# Removes parallel workflow commands from Claude Code

set -e

echo "Uninstalling Claude Minions..."
echo ""

COMMANDS_DIR="$HOME/.claude/commands"

# Remove command files
echo "Removing commands..."
rm -f "$COMMANDS_DIR/plan-parallel.md"
rm -f "$COMMANDS_DIR/work-on.md"
rm -f "$COMMANDS_DIR/merge-parallel.md"
rm -f "$COMMANDS_DIR/worktree-review.md"

echo "Uninstall complete!"
echo ""
echo "Note: Any existing .claude-workspace directories in your projects are preserved."
echo "You can manually remove them if needed."
