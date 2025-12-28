#!/bin/bash
# Claude Minions Installer
# Installs parallel workflow commands for Claude Code

set -e

echo "Installing Claude Minions..."
echo ""

# Create commands directory if it doesn't exist
COMMANDS_DIR="$HOME/.claude/commands"
mkdir -p "$COMMANDS_DIR"

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Copy command files
echo "Installing commands..."
cp "$SCRIPT_DIR/commands/plan-parallel.md" "$COMMANDS_DIR/"
cp "$SCRIPT_DIR/commands/work-on.md" "$COMMANDS_DIR/"
cp "$SCRIPT_DIR/commands/merge-parallel.md" "$COMMANDS_DIR/"
cp "$SCRIPT_DIR/commands/worktree-review.md" "$COMMANDS_DIR/"

echo "Installation complete!"
echo ""
echo "Available commands:"
echo "  /plan-parallel <feature> - Create a parallel development plan"
echo "  /work-on <subtask>       - Work on a specific subtask"
echo "  /worktree-review         - Review current subtask progress"
echo "  /merge-parallel <branch> - Merge all completed subtasks"
echo ""
echo "Get started: Run 'claude code' and use /plan-parallel"
