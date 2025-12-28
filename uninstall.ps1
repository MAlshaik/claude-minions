# Claude Minions Uninstaller (PowerShell)
# Removes parallel workflow commands from Claude Code on Windows

Write-Host "Uninstalling Claude Minions..." -ForegroundColor Cyan
Write-Host ""

$CommandsDir = "$env:USERPROFILE\.claude\commands"

# Remove command files
Write-Host "Removing commands..." -ForegroundColor Yellow
Remove-Item "$CommandsDir\plan-parallel.md" -ErrorAction SilentlyContinue
Remove-Item "$CommandsDir\work-on.md" -ErrorAction SilentlyContinue
Remove-Item "$CommandsDir\merge-parallel.md" -ErrorAction SilentlyContinue
Remove-Item "$CommandsDir\worktree-review.md" -ErrorAction SilentlyContinue

Write-Host "Uninstall complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Note: Any existing .claude-workspace directories in your projects are preserved."
Write-Host "You can manually remove them if needed."
