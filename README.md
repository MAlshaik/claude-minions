# Claude Minions

sup guys this is the multi agent coding setup that i use in claude code 

## Overview

Claude Minions enables you to run multiple Claude Code instances in parallel, each working on independent subtasks of a larger feature. This dramatically speeds up development by allowing Claude to work on multiple parts of your codebase simultaneously using Git worktrees.

## Features

- **Intelligent task decomposition** - Automatically breaks features into independent subtasks
- **Dependency management** - Tracks dependencies between subtasks to ensure correct execution order
- **Parallel execution** - Run multiple Claude instances simultaneously, each in isolated worktrees
- **Conflict detection** - Identifies potential file conflicts before they happen
- **Automated merging** - Merges completed subtasks in the correct dependency order

## Prerequisites

- Git
- Claude Code CLI
- **Windows users**: Git Bash (included with Git for Windows)

## Installation

### macOS / Linux / Git Bash (Windows)

```bash
git clone https://github.com/yourusername/claude-minions.git
cd claude-minions
./install.sh
```

### Windows (PowerShell)

**Note: Windows installation scripts are untested. Please report any issues.**

```powershell
git clone https://github.com/yourusername/claude-minions.git
cd claude-minions
.\install.ps1
```

### Manual Installation (All Platforms)

If the installation scripts don't work, you can manually copy the command files:

```bash
# Clone the repository
git clone https://github.com/yourusername/claude-minions.git
cd claude-minions

# Copy commands to Claude Code's commands directory
# macOS/Linux/Git Bash:
cp commands/*.md ~/.claude/commands/

# Windows PowerShell:
# Copy-Item commands\*.md $env:USERPROFILE\.claude\commands\
```

## Usage

### 1. Plan a feature for parallel development

```bash
claude code
/plan-parallel "Add user authentication system"
```

This creates a `.claude-workspace/` directory with:
- `PARALLEL_PLAN.md` - Overall feature plan and subtask breakdown
- `worktrees/<subtask>/TASK.md` - Detailed instructions for each subtask
- `worktrees/<subtask>/STATUS.yml` - Execution status tracking
- `scripts/` - Helper utilities for worktree management

### 2. Work on subtasks (in parallel)

Open multiple terminals and start working on independent subtasks:

**Terminal 1:**
```bash
cd your-project
claude code
/work-on subtask-1-user-model
```

**Terminal 2:**
```bash
cd your-project
claude code
/work-on subtask-2-auth-controller
```

**Terminal 3:**
```bash
cd your-project
claude code
/work-on subtask-3-session-management
```

Each instance works in an isolated Git worktree, preventing conflicts.

### 3. Review progress

Check the status of all subtasks:

```bash
bash .claude-workspace/scripts/status-check.sh
```

Or review your current subtask:

```bash
/worktree-review
```

### 4. Merge when complete

Once all subtasks are done, merge them in dependency order:

```bash
/merge-parallel main
```

This automatically:
- Validates all subtasks are complete
- Merges in correct dependency order
- Runs tests after each merge
- Cleans up worktrees and branches

## Commands

| Command | Description |
|---------|-------------|
| `/plan-parallel <feature>` | Analyze codebase and create a parallel development plan |
| `/work-on <subtask>` | Set up worktree and start working on a specific subtask |
| `/worktree-review` | Review current subtask progress and status |
| `/merge-parallel <branch>` | Merge all completed subtasks into target branch |

## How It Works

### Architecture

Claude Minions uses Git worktrees to create isolated working directories for each subtask. Each worktree:
- Has its own branch (`parallel/subtask-name`)
- Contains complete project files
- Can be worked on independently
- Tracks its own status and dependencies

### Workflow

1. **Planning Phase**
   - Analyzes codebase architecture
   - Identifies integration points and dependencies
   - Breaks feature into 2-6 independent subtasks
   - Creates detailed implementation plans

2. **Execution Phase**
   - Each Claude instance works in isolated worktree
   - Validates dependencies before starting
   - Tracks progress and status
   - Detects potential conflicts

3. **Integration Phase**
   - Merges subtasks in dependency order
   - Runs tests after each merge
   - Validates integration points
   - Cleans up worktrees

### Directory Structure

```
your-project/
├── .claude-workspace/          # Created by /plan-parallel
│   ├── PARALLEL_PLAN.md        # Overall feature plan
│   ├── worktrees/
│   │   ├── subtask-1/
│   │   │   ├── TASK.md         # Task instructions
│   │   │   ├── STATUS.yml      # Execution status
│   │   │   └── worktree/       # Git worktree (gitignored)
│   │   └── subtask-2/
│   │       └── ...
│   ├── integration/
│   │   └── MERGE_PLAN.md       # Merge strategy
│   └── scripts/
│       ├── worktree-setup.sh
│       ├── status-check.sh
│       └── validate-dependencies.sh
└── [your project files]
```

## Examples

See [examples/example-workflow.md](examples/example-workflow.md) for a complete walkthrough.

## Best Practices

- **Start with planning** - Let Claude analyze dependencies before jumping into code
- **Keep subtasks focused** - Aim for 2-8 hours of work per subtask
- **Minimize file overlap** - Better parallelization with less shared files
- **Use dependency tracking** - Work on independent subtasks first
- **Review before merging** - Use `/worktree-review` to verify completion

## Limitations

- Requires Git repository
- Works best with well-structured codebases
- Subtasks must be reasonably independent
- Maximum efficiency with 3-6 parallel instances

## Uninstall

### macOS / Linux / Git Bash (Windows)
```bash
./uninstall.sh
```

### Windows (PowerShell)
```powershell
.\uninstall.ps1
```

This removes the commands but preserves any existing `.claude-workspace` directories in your projects.

## Contributing

Contributions welcome! Please open an issue or PR.

## License

MIT
