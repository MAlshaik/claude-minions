---
name: worktree-review
description: Reviews changes in current worktree for quality and completeness
argument-hint: ""
---

# Worktree Review

Review changes in the current worktree to ensure quality, completeness, and adherence to subtask requirements.

## Workflow

### Phase 1: Detect Context

Determine current worktree and load subtask information:

```bash
CURRENT_PATH=$(pwd)
GIT_ROOT=$(git rev-parse --show-toplevel)

# Check if in a parallel subtask worktree
if [[ "$CURRENT_PATH" == *".claude-workspace/worktrees/"* ]]; then
  # Extract subtask name from path
  SUBTASK_NAME=$(echo "$CURRENT_PATH" | sed 's/.*worktrees\/\([^\/]*\).*/\1/')
else
  echo "❌ Not in a subtask worktree"
  echo ""
  echo "Available worktrees:"
  ls -1 .claude-workspace/worktrees/ 2>/dev/null || echo "  No worktrees found"
  echo ""
  echo "Navigate to a worktree first:"
  echo "  cd .claude-workspace/worktrees/<subtask-name>/worktree/"
  exit 1
fi
```

Load subtask context:
- Read `.claude-workspace/worktrees/<subtask>/TASK.md`
- Read `.claude-workspace/worktrees/<subtask>/STATUS.yml`
- Get changed files: `git diff --name-only main...HEAD`

### Phase 2: Completeness Check

Verify subtask completeness:

**1. Check files mentioned in TASK.md**:
- Parse "Files to Create/Modify" section
- Verify each file was actually created/modified
- Report any missing files

**2. Check acceptance criteria**:
- Parse "Acceptance Criteria" section from TASK.md
- For each criterion, verify if addressed in changes
- Note which criteria may not be met

**3. Check tests**:
- Verify test files exist
- Check if tests cover new functionality
- Note if tests are missing

### Phase 3: Quality Review

Launch parallel review agents:

- Task code-simplicity-reviewer(prompt="Review the changes in this worktree for simplicity and maintainability. Check for over-engineering, unnecessary abstractions, or complex code that could be simplified.")

- Task performance-oracle(prompt="Analyze changes for performance issues. Check for inefficient algorithms, N+1 queries, missing indexes, or scalability concerns.")

- Task security-sentinel(prompt="Scan changes for security vulnerabilities. Check for SQL injection, XSS, authentication issues, insecure data handling, or exposed secrets.")

### Phase 4: Test Verification

Run the test suite:

```bash
# Run tests (adapt command to project)
[test command - e.g., bin/rails test, npm test, pytest, etc.]

# Capture result
TEST_RESULT=$?
```

Record whether tests pass or fail.

### Phase 5: Conflict Detection

Check for potential conflicts with other in-progress subtasks:

```bash
# Get files modified in this subtask
MY_FILES=$(git diff --name-only main...HEAD)

# Check other subtasks
for other_status in ../*/ STATUS.yml; do
  OTHER_SUBTASK=$(basename $(dirname "$other_status"))

  # Skip self
  [[ "$OTHER_SUBTASK" == "$SUBTASK_NAME" ]] && continue

  # Check if other subtask is in progress
  OTHER_STATUS_VALUE=$(grep "^status:" "$other_status" | awk '{print $2}')
  [[ "$OTHER_STATUS_VALUE" != "in_progress" ]] && continue

  # Get their worktree path
  OTHER_WORKTREE=$(grep "^worktree_path:" "$other_status" | awk '{print $2}')

  if [[ -d "$OTHER_WORKTREE" ]]; then
    # Get their modified files
    OTHER_FILES=$(cd "$OTHER_WORKTREE" && git diff --name-only main...HEAD 2>/dev/null)

    # Find overlaps
    for my_file in $MY_FILES; do
      if echo "$OTHER_FILES" | grep -q "^${my_file}$"; then
        echo "⚠️ Conflict detected: $my_file also modified in $OTHER_SUBTASK"
      fi
    done
  fi
done
```

### Phase 6: Generate Review Report

Create `.claude-workspace/worktrees/<subtask>/REVIEW.md`:

```markdown
---
subtask: <subtask-name>
reviewed_at: [current timestamp]
branch: parallel/<subtask-name>
commit: [git rev-parse HEAD]
reviewer: Claude Code
---

# Review: <subtask-name>

## Summary

**Status**: [PASS | FAIL | WARNINGS]
**Tests**: [PASSING | FAILING | NOT RUN]
**Conflicts**: [NONE | DETECTED]
**Recommendation**: [APPROVE | REQUEST CHANGES]

## Objective

[Objective from TASK.md]

## Acceptance Criteria

[For each criterion from TASK.md:]
- [✓ | ✗ | ?] Criterion text
  [Brief verification note]

- [✓ | ✗] All tests passing
- [✓ | ✗] No security issues detected
- [✓ | ✗] Follows existing patterns

## Files Changed

[For each changed file:]
- `path/to/file.rb` (+50, -10) [NEW | MODIFIED | DELETED]

Total: N files changed, +X insertions, -Y deletions

## Code Quality Review

### Simplicity & Maintainability

[Summary from code-simplicity-reviewer agent]

**Key findings:**
- [Finding 1]
- [Finding 2]

### Performance

[Summary from performance-oracle agent]

**Key findings:**
- [Finding 1]
- [Finding 2]

### Security

[Summary from security-sentinel agent]

**Key findings:**
- [Finding 1]
- [Finding 2]

## Test Results

```
[Test output summary]
```

**Test coverage**: [assessment of test completeness]

## Potential Conflicts

[If conflicts detected:]
⚠️ The following files are also being modified in other in-progress subtasks:

- `path/to/file.rb` - Also modified in `subtask-X`
  **Recommendation**: Coordinate with other subtask or resolve during merge

[If no conflicts:]
✅ No file conflicts detected with other in-progress subtasks

## Code Patterns

**Follows existing patterns**: [YES | NO | MOSTLY]

[Note any deviations from project conventions]

## Recommendations

[If PASS:]
1. ✅ Code quality is good
2. ✅ All acceptance criteria met
3. ✅ Ready for merge

[If WARNINGS:]
1. ⚠️ [Specific issue to address]
2. ⚠️ [Another concern]

Consider addressing these before marking complete.

[If FAIL:]
1. ❌ [Critical issue 1]
2. ❌ [Critical issue 2]

Must fix before completing this subtask.

## Next Steps

[If approved:]
- Mark subtask as complete
- Push branch
- Update STATUS.yml

[If changes needed:]
- Address recommendations
- Re-run tests
- Run /worktree-review again
```

### Phase 7: Display Results

Show summary to user:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Review Complete: <subtask-name>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Status: [PASS / FAIL / WARNINGS]

✓ Acceptance criteria: N/M met
✓ Tests: [PASSING / FAILING / NOT RUN]
✓ Security: [No issues / Issues found]
✓ Conflicts: [None / Detected]

Full report: .claude-workspace/worktrees/<subtask>/REVIEW.md

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[If PASS:]
  ✅ Ready to merge!

  Next steps:
  1. Continue to another subtask: /work-on <name>
  2. Merge all subtasks: /merge-parallel main

[If WARNINGS:]
  ⚠️ Issues found (see REVIEW.md for details)

  Recommendations:
  - [Top 3 recommendations]

  You can proceed, but consider addressing these first.

[If FAIL:]
  ❌ Critical issues found (see REVIEW.md for details)

  Must fix:
  - [Critical issue 1]
  - [Critical issue 2]

  Fix issues and re-run /worktree-review when ready.
```

## Error Handling

**Not in worktree**:
- Error message with clear instructions
- List available worktrees
- Show command to navigate to a worktree

**No changes detected**:
- "No changes detected in this worktree"
- Show: `git diff --stat main...HEAD`
- Suggest making changes or checking if in correct directory

**Tests not found**:
- Warning: "Could not run tests (no test command found)"
- Ask user: "What command should I use to run tests in this project?"
- Proceed with review but note tests were not verified

**Review agents fail**:
- Continue with review but note which agents failed
- Include partial results in report
- Don't block on agent failures
