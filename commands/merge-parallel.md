---
name: merge-parallel
description: Merges all subtask branches in dependency order into target branch
argument-hint: "<target-branch>"
---

# Merge Parallel Subtasks

Merge all completed subtasks from the parallel plan into the target branch in dependency order.

## Target Branch

#$ARGUMENTS

**If target branch is empty:** Default to `main`

## Prerequisites

- Must run from **main worktree** (not a subtask worktree)
- All subtasks must be complete (status: complete in STATUS.yml)
- No uncommitted changes in main worktree

## Workflow

### Phase 1: Pre-Flight Checks

**1. Verify location**:

```bash
CURRENT_PATH=$(pwd)

if [[ "$CURRENT_PATH" == *".claude-workspace/worktrees/"* ]]; then
  echo "❌ Cannot merge from subtask worktree"
  echo "Navigate to main repository first:"
  echo "  cd $(git rev-parse --show-toplevel)"
  exit 1
fi
```

**2. Check plan exists**:

```bash
if [[ ! -f .claude-workspace/PARALLEL_PLAN.md ]]; then
  echo "❌ No parallel plan found"
  exit 1
fi
```

**3. Verify all subtasks complete**:

```bash
INCOMPLETE=()

for status_file in .claude-workspace/worktrees/*/STATUS.yml; do
  STATUS=$(grep "^status:" "$status_file" | awk '{print $2}')

  if [[ "$STATUS" != "complete" ]]; then
    SUBTASK=$(basename $(dirname "$status_file"))
    INCOMPLETE+=("$SUBTASK ($STATUS)")
  fi
done

if [[ ${#INCOMPLETE[@]} -gt 0 ]]; then
  echo "❌ Cannot merge: ${#INCOMPLETE[@]} subtask(s) incomplete:"
  for subtask in "${INCOMPLETE[@]}"; do
    echo "  - $subtask"
  done
  echo ""
  echo "Complete all subtasks first or remove incomplete ones from the plan."
  exit 1
fi
```

**4. Check working directory clean**:

```bash
if [[ -n $(git status --porcelain) ]]; then
  echo "❌ Working directory has uncommitted changes:"
  git status --short
  echo ""
  echo "Commit or stash changes before merging."
  exit 1
fi
```

**5. Load merge order**:

Read merge order from `.claude-workspace/integration/MERGE_PLAN.md`:

```bash
# Extract merge order from YAML frontmatter
MERGE_ORDER=$(awk '/^---$/,/^---$/ {print}' .claude-workspace/integration/MERGE_PLAN.md | grep "^merge_order:" | sed 's/merge_order: \[\(.*\)\]/\1/' | tr ',' ' ' | tr -d '[]')
```

**6. Confirm with user**:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Ready to merge N subtasks into <target-branch>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Merge order (dependency-based):
[For each subtask in order:]
  N. <subtask-name> (parallel/<branch-name>)

This will:
- Checkout <target-branch>
- Pull latest from origin
- Merge each branch in order
- Run tests after each merge
- Push to origin if all successful

Continue? (y/n)
```

If user says no, exit.

### Phase 2: Prepare Target Branch

```bash
TARGET_BRANCH="<target-branch>"

echo "Checking out $TARGET_BRANCH..."
git checkout "$TARGET_BRANCH"

echo "Pulling latest from origin..."
git pull origin "$TARGET_BRANCH" || echo "Warning: Could not pull from origin (might be offline)"

# Create merge log
mkdir -p .claude-workspace/integration

cat > .claude-workspace/integration/MERGE_LOG.md << EOF
# Merge Log - $(date -u)

Target: $TARGET_BRANCH
Started: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

## Merges

EOF
```

### Phase 3: Execute Merges

For each subtask in merge order:

```bash
for SUBTASK in $MERGE_ORDER; do
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📦 Merging $SUBTASK..."
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Get branch name from STATUS.yml
  BRANCH=$(grep "^branch:" ".claude-workspace/worktrees/$SUBTASK/STATUS.yml" | awk '{print $2}')

  # Get objective from TASK.md
  OBJECTIVE=$(grep "## Objective" ".claude-workspace/worktrees/$SUBTASK/TASK.md" -A 1 | tail -1 | sed 's/^[ \t]*//')

  # Fetch branch
  echo "Fetching $BRANCH..."
  git fetch origin "$BRANCH" 2>/dev/null || true

  # Attempt merge
  MERGE_MSG="Merge $SUBTASK: $OBJECTIVE

Subtask ID: $SUBTASK
Branch: $BRANCH

🤖 Generated with [Claude Code](https://claude.com/claude-code)"

  if git merge --no-ff "$BRANCH" -m "$MERGE_MSG"; then
    echo "✅ $SUBTASK merged successfully" | tee -a .claude-workspace/integration/MERGE_LOG.md

    # Run tests after merge
    echo ""
    echo "🧪 Running tests after merge..."

    # Try to detect test command from common patterns
    TEST_CMD=""
    if [[ -f "bin/rails" ]]; then
      TEST_CMD="bin/rails test"
    elif [[ -f "package.json" ]] && grep -q "\"test\":" package.json; then
      TEST_CMD="npm test"
    elif [[ -f "pytest.ini" ]] || [[ -f "setup.py" ]]; then
      TEST_CMD="pytest"
    fi

    if [[ -n "$TEST_CMD" ]]; then
      if $TEST_CMD; then
        echo "✅ Tests passing after $SUBTASK merge" | tee -a .claude-workspace/integration/MERGE_LOG.md
      else
        echo "❌ Tests FAILED after $SUBTASK merge" | tee -a .claude-workspace/integration/MERGE_LOG.md
        echo ""
        echo "Tests failed after merging $SUBTASK"
        echo ""
        echo "Options:"
        echo "1. Fix tests now and continue"
        echo "2. Abort merge (git merge --abort)"
        echo ""
        read -p "Choose (1 or 2): " choice

        if [[ "$choice" == "2" ]]; then
          git merge --abort
          echo "❌ Merge aborted" | tee -a .claude-workspace/integration/MERGE_LOG.md
          exit 1
        else
          echo "Waiting for you to fix tests..."
          echo "When ready, type 'continue' to proceed with next merge:"
          read -p "> " continue_cmd
          if [[ "$continue_cmd" != "continue" ]]; then
            exit 1
          fi
        fi
      fi
    else
      echo "⚠️ Could not detect test command - skipping tests" | tee -a .claude-workspace/integration/MERGE_LOG.md
    fi

  else
    # Merge conflict
    echo "❌ CONFLICT merging $SUBTASK" | tee -a .claude-workspace/integration/MERGE_LOG.md
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Merge conflict detected in $SUBTASK"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Conflicting files:"
    git status --short | grep "^UU"
    echo ""
    echo "Resolve conflicts and then:"
    echo "1. Stage resolved files: git add <files>"
    echo "2. Complete merge: git commit"
    echo "3. Run tests to verify"
    echo "4. Re-run /merge-parallel $TARGET_BRANCH to continue"
    echo ""
    echo "Or abort merge: git merge --abort"
    exit 1
  fi
done
```

### Phase 4: Final Verification

```bash
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 Running final integration tests..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Run full test suite
if [[ -n "$TEST_CMD" ]]; then
  if $TEST_CMD; then
    echo "✅ All integration tests passing" | tee -a .claude-workspace/integration/MERGE_LOG.md
  else
    echo "❌ Integration tests FAILED" | tee -a .claude-workspace/integration/MERGE_LOG.md
    echo ""
    echo "Integration tests failed. Fix issues before pushing."
    echo ""
    echo "You can:"
    echo "1. Fix issues and continue"
    echo "2. Reset to before merge: git reset --hard origin/$TARGET_BRANCH"
    exit 1
  fi
fi
```

### Phase 5: Push and Cleanup

**1. Push to origin**:

```bash
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "All merges complete and tests passing!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Push to origin/$TARGET_BRANCH? (y/n)"
read -r response

if [[ "$response" == "y" ]]; then
  git push origin "$TARGET_BRANCH"
  echo "✅ Pushed to origin/$TARGET_BRANCH" | tee -a .claude-workspace/integration/MERGE_LOG.md
else
  echo "⚠️ Not pushed to origin (you can push manually later)" | tee -a .claude-workspace/integration/MERGE_LOG.md
fi
```

**2. Update merge log**:

```bash
cat >> .claude-workspace/integration/MERGE_LOG.md << EOF

## Completion

Completed: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
Status: SUCCESS
Target Branch: $TARGET_BRANCH
Subtasks Merged: ${#MERGE_ORDER[@]}
EOF
```

**3. Ask about cleanup**:

```bash
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Clean up worktrees and branches? (y/n)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "This will:"
echo "  - Remove local worktrees"
echo "  - Optionally delete remote branches"
echo ""
read -r cleanup_response

if [[ "$cleanup_response" == "y" ]]; then
  echo ""
  echo "Removing worktrees..."

  # Remove worktrees
  for worktree_path in .claude-workspace/worktrees/*/worktree; do
    if [[ -d "$worktree_path" ]]; then
      echo "  Removing $(basename $(dirname $worktree_path))"
      git worktree remove "$worktree_path" --force 2>/dev/null || true
    fi
  done

  echo ""
  echo "Delete remote branches? (y/n)"
  read -r delete_remote

  if [[ "$delete_remote" == "y" ]]; then
    echo ""
    echo "Deleting remote branches..."

    for SUBTASK in $MERGE_ORDER; do
      BRANCH=$(grep "^branch:" ".claude-workspace/worktrees/$SUBTASK/STATUS.yml" | awk '{print $2}')
      echo "  Deleting $BRANCH"
      git push origin --delete "$BRANCH" 2>/dev/null || true
      git branch -d "$BRANCH" 2>/dev/null || true
    done
  fi

  echo ""
  echo "✅ Cleanup complete"
fi
```

**4. Display summary**:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Parallel Merge Complete!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 Summary:
  - Subtasks merged: N
  - Target branch: <target-branch>
  - All tests: PASSING
  - Merge log: .claude-workspace/integration/MERGE_LOG.md

🎉 Feature complete and integrated!

Next steps:
  - Create PR from <target-branch> (if applicable)
  - Deploy to staging/production
  - Archive parallel workspace (optional):
      mv .claude-workspace .claude-workspace-archived-$(date +%Y%m%d)
```

## Error Handling

**Incomplete subtasks**:
- List which subtasks are incomplete with their current status
- Show command to check status: `bash .claude-workspace/scripts/status-check.sh`
- Suggest using `/work-on <subtask>` to complete them
- Exit with error

**Merge conflicts**:
- Stop immediately at first conflict
- Show conflicting files clearly
- Provide step-by-step resolution instructions
- Suggest re-running command after resolution
- Do not continue to next subtask

**Test failures**:
- Stop at first failure
- Show test output
- Allow user to:
  1. Fix and continue
  2. Abort entire merge
- Do not proceed if tests fail

**Not in main worktree**:
- Clear error message
- Show command to navigate to main worktree
- Exit with error

**Uncommitted changes**:
- Show uncommitted files
- Suggest: `git status` to review
- Suggest: `git commit` or `git stash`
- Exit with error

**Target branch doesn't exist**:
- Ask: "Branch <target-branch> doesn't exist. Create it? (y/n)"
- If yes: `git checkout -b <target-branch>`
- If no: Exit with error

**No origin remote**:
- Warning: "No origin remote configured"
- Skip fetch/pull/push operations
- Continue with local merges only
- Note in merge log
