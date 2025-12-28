# Claude Minions Installer (PowerShell)
# Installs parallel workflow commands for Claude Code on Windows

Write-Host "Installing Claude Minions..." -ForegroundColor Cyan
Write-Host ""

# Create commands directory if it doesn't exist
$CommandsDir = "$env:USERPROFILE\.claude\commands"
New-Item -ItemType Directory -Force -Path $CommandsDir | Out-Null

# Get the directory where this script is located
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Copy command files
Write-Host "Installing commands..." -ForegroundColor Yellow
Copy-Item "$ScriptDir\commands\plan-parallel.md" "$CommandsDir\" -Force
Copy-Item "$ScriptDir\commands\work-on.md" "$CommandsDir\" -Force
Copy-Item "$ScriptDir\commands\merge-parallel.md" "$CommandsDir\" -Force
Copy-Item "$ScriptDir\commands\worktree-review.md" "$CommandsDir\" -Force

Write-Host "Installation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Available commands:"
Write-Host "  /plan-parallel <feature> - Create a parallel development plan"
Write-Host "  /work-on <subtask>       - Work on a specific subtask"
Write-Host "  /worktree-review         - Review current subtask progress"
Write-Host "  /merge-parallel <branch> - Merge all completed subtasks"
Write-Host ""
Write-Host "Get started: Run 'claude code' and use /plan-parallel"
