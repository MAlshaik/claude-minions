---
name: work-on
description: Loads subtask context and sets up worktree for parallel development
argument-hint: "<subtask-name>"
---

# Work On Subtask

Load a subtask from the parallel plan and set up an isolated worktree for development.

## Subtask Name

#$ARGUMENTS

**If subtask name is empty:**

List available subtasks from `.claude-workspace/PARALLEL_PLAN.md` and ask: "Which subtask would you like to work on?"

## Workflow

### Phase 1: Validate Subtask

Check if parallel plan exists:

```bash
if [[ ! -f .claude-workspace/PARALLEL_PLAN.md ]]; then
  echo "❌ No parallel plan found. Run /plan-parallel first."
  exit 1
fi
```

Load subtask files:
- Read `.claude-workspace/worktrees/<subtask>/TASK.md`
- Read `.claude-workspace/worktrees/<subtask>/STATUS.yml`

If subtask not found, list available subtasks and ask user to select.

### Phase 2: Check Dependencies

Validate dependencies using the helper script:

```bash
bash .claude-workspace/scripts/validate-dependencies.sh <subtask-name>
```

If dependencies are not met:
- Show which dependencies are incomplete
- Ask: "⚠️ Warning: This subtask depends on incomplete subtasks. Continue anyway? (for testing only)"
- If user says no, stop and suggest working on dependencies first
- If user says yes, proceed but note in STATUS.yml

### Phase 3: Check Lock Status

Check if another Claude instance is working on this subtask:

```bash
LOCK_FILE=".claude-workspace/worktrees/<subtask>/.lock"

if [[ -f "$LOCK_FILE" ]]; then
  PID=$(head -1 "$LOCK_FILE")
  LOCK_TIME=$(tail -1 "$LOCK_FILE")

  # Check if lock is stale (>4 hours old)
  if [ lock is stale ]; then
    echo "⚠️ Stale lock detected (>4 hours old)"
    echo "Process ID: $PID"
    echo "Lock time: $LOCK_TIME"
    echo "Take over this subtask? (y/n)"
    # If yes, remove lock and continue
    # If no, exit
  else
    echo "⚠️ Another Claude instance may be working on this subtask"
    echo "Lock file: $LOCK_FILE"
    echo "Process ID: $PID"
    echo "Continue anyway? (y/n)"
    # If yes, proceed with caution
    # If no, exit
  fi
fi
```

### Phase 4: Set Up Worktree

Determine base branch:
- If no dependencies: base = `main`
- If dependencies exist: base = `main` (dependencies will be merged later)
- User can override if needed

Create worktree using helper script:

```bash
bash .claude-workspace/scripts/worktree-setup.sh \
  --subtask "<subtask-name>" \
  --branch "parallel/<subtask-name>" \
  --base "main"
```

This creates:
- Worktree at `.claude-workspace/worktrees/<subtask>/worktree/`
- Updates `STATUS.yml` to `in_progress`
- Copies `.env` files
- Writes lock file with current PID

### Phase 5: Load Context

Display subtask information:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 Subtask: <subtask-name>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎯 Objective: [from TASK.md]

⏱️ Estimated: N hours
📦 Dependencies: [list or "None"]
🌿 Branch: parallel/<subtask-name>
📁 Worktree: .claude-workspace/worktrees/<subtask>/worktree/

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Read key reference files mentioned in TASK.md:
- Files to be modified
- Similar patterns/implementations
- Related tests

Create TodoWrite list from TASK.md:
- Parse implementation steps
- Parse acceptance criteria
- Create structured todo items

### Phase 6: Navigate to Worktree

Change to the worktree directory:

```bash
cd .claude-workspace/worktrees/<subtask>/worktree/
```

Note: All subsequent work happens in this isolated directory.

### Phase 7: Execute Implementation

Follow the implementation plan from TASK.md:

1. **Read existing code**:
   - Examine files mentioned in TASK.md
   - Understand patterns and conventions
   - Identify integration points

2. **Implement changes**:
   - Create/modify files as specified
   - Follow existing patterns
   - Add comprehensive tests
   - Keep changes focused on subtask scope

3. **Run tests continuously**:
   - After each significant change
   - Ensure no regressions
   - Verify acceptance criteria

4. **Track progress**:
   - Update TodoWrite as tasks complete
   - Periodically check for file conflicts with other subtasks
   - Keep commits small and focused

### Phase 8: Completion

When all acceptance criteria are met:

**1. Run final checks**:

```bash
# Run test suite
[appropriate test command for the project]

# Check linting (if applicable)
[appropriate lint command]
```

**2. Commit changes**:

```bash
git add .
git commit -m "feat(subtask-N): [Objective from TASK.md]

[Brief description of what was implemented]

Subtask: <subtask-name>
Priority: N
Estimated: N hours

Acceptance Criteria:
- ✓ [Criterion 1]
- ✓ [Criterion 2]
- ✓ All tests passing

Files modified:
- [key files]

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

**3. Push branch**:

```bash
git push -u origin parallel/<subtask-name>
```

**4. Update STATUS.yml**:

Update `.claude-workspace/worktrees/<subtask>/STATUS.yml`:

```yaml
status: complete
completed_at: [current timestamp]
commit_sha: [git rev-parse HEAD]
tests_passing: true
```

**5. Release lock**:

```bash
rm -f .claude-workspace/worktrees/<subtask>/.lock
```

**6. Update main plan**:

Update `.claude-workspace/PARALLEL_PLAN.md`:
- Increment `completed_subtasks` counter
- Update subtask status to `complete`

**7. Display completion message**:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Subtask Complete: <subtask-name>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 Progress:
- Completed: N/M subtasks
- Remaining: [list of pending subtasks]
- Ready to work: [list of subtasks with dependencies now met]

Next steps:
1. Work on another subtask: /work-on <name>
2. Review this subtask: /worktree-review
3. Merge all (when complete): /merge-parallel main

Return to main worktree: cd $(git rev-parse --show-toplevel)
```

## Error Handling

**Subtask not found**:
- List all available subtasks from `.claude-workspace/worktrees/`
- Ask user to select a valid one

**Dependencies not met**:
- Show which dependencies are incomplete with their current status
- Offer to:
  1. Wait (stop and suggest working on dependencies)
  2. Continue anyway (for testing/development)

**Worktree already exists**:
- Check STATUS.yml status
- If `complete`: "Subtask already complete. Work on it again? (y/n)"
- If `in_progress`: Show lock info, offer to take over or abort
- If lock is stale (>4 hours): Automatically offer to take over

**No parallel plan**:
- Error: "❌ No parallel plan found. Run /plan-parallel first to create a parallel development plan."

**Already in a worktree**:
- Detect if current directory is inside `.claude-workspace/worktrees/`
- Error: "❌ Already in a worktree. Navigate to main repository first: cd $(git rev-parse --show-toplevel)"
