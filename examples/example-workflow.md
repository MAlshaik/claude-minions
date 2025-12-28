# Example Workflow: Building a User Authentication System

This example demonstrates using Claude Minions to build a complete authentication system in parallel.

## Scenario

You have a Rails application and want to add user authentication with email/password login, session management, and password reset functionality.

## Step 1: Create the Parallel Plan

Open Claude Code in your project:

```bash
cd my-rails-app
claude code
```

Create the plan:

```
You: /plan-parallel Add complete user authentication system with email/password login, sessions, and password reset
```

Claude analyzes your codebase and creates a plan with 4 subtasks:

- **subtask-1-user-model** - Create User model with password encryption
- **subtask-2-sessions-controller** - Implement login/logout controllers
- **subtask-3-password-reset** - Add password reset flow with email
- **subtask-4-integration** - Wire everything together with routes and middleware

The dependency graph shows:
- subtask-1 has no dependencies (can start immediately)
- subtask-2 depends on subtask-1
- subtask-3 depends on subtask-1
- subtask-4 depends on subtask-2 and subtask-3

## Step 2: Work on Independent Subtasks in Parallel

### Terminal 1: User Model (no dependencies)

```bash
cd my-rails-app
claude code
```

```
You: /work-on subtask-1-user-model
```

Claude:
1. Creates worktree at `.claude-workspace/worktrees/subtask-1-user-model/worktree/`
2. Creates branch `parallel/subtask-1-user-model`
3. Reads the task from `TASK.md`
4. Implements:
   - User model with email/password fields
   - Password encryption using bcrypt
   - Validations
   - Unit tests
5. Runs tests to verify
6. Commits and pushes
7. Updates STATUS.yml to "complete"

### Terminal 2: Monitor Progress

While subtask-1 is running, check status:

```bash
bash .claude-workspace/scripts/status-check.sh
```

Output:
```
Parallel Development Status

Summary:
  Total subtasks: 4
  Complete: 0
  In Progress: 1
  Pending: 3
  Blocked: 0

Subtasks:
  In Progress  subtask-1-user-model       [P1] in_progress
  Pending      subtask-2-sessions         [P2] pending
  Pending      subtask-3-password-reset   [P2] pending
  Pending      subtask-4-integration      [P3] pending
```

## Step 3: Work on Dependent Subtasks

Once subtask-1 completes, subtask-2 and subtask-3 can start in parallel:

### Terminal 1: Sessions Controller

```
You: /work-on subtask-2-sessions
```

Claude validates dependencies, sees subtask-1 is complete, and proceeds.

### Terminal 2: Password Reset

```
You: /work-on subtask-3-password-reset
```

Claude validates dependencies, sees subtask-1 is complete, and proceeds.

Both instances work simultaneously in isolated worktrees without conflicts.

## Step 4: Integration Subtask

Once subtask-2 and subtask-3 complete:

### Terminal 1: Integration

```
You: /work-on subtask-4-integration
```

Claude:
1. Validates both dependencies are complete
2. Creates worktree
3. Wires together:
   - Routes for all auth endpoints
   - Authentication middleware
   - Integration tests
4. Runs full test suite
5. Commits and completes

## Step 5: Review and Merge

Check all subtasks are complete:

```bash
bash .claude-workspace/scripts/status-check.sh
```

Output:
```
Summary:
  Total subtasks: 4
  Complete: 4
  In Progress: 0
  Pending: 0
  Blocked: 0
```

Merge everything:

```
You: /merge-parallel main
```

Claude:
1. Reads merge plan from `.claude-workspace/integration/MERGE_PLAN.md`
2. Merges in dependency order:
   - First: subtask-1-user-model
   - Then: subtask-2-sessions and subtask-3-password-reset
   - Finally: subtask-4-integration
3. Runs tests after each merge
4. Cleans up worktrees and branches
5. Confirms feature is complete

## Results

The entire authentication system was built with:
- 4 subtasks worked on in parallel (where dependencies allowed)
- No merge conflicts (proper file isolation)
- All tests passing
- Complete in a fraction of sequential time

## Timeline Comparison

**Sequential (traditional approach):**
- subtask-1: 3 hours
- subtask-2: 4 hours
- subtask-3: 4 hours
- subtask-4: 2 hours
- **Total: 13 hours**

**Parallel (with Claude Minions):**
- Wave 1: subtask-1 (3 hours)
- Wave 2: subtask-2 + subtask-3 in parallel (4 hours max)
- Wave 3: subtask-4 (2 hours)
- **Total: 9 hours** (31% faster)

With more independent subtasks, the speedup is even greater.

## Key Takeaways

1. **Planning is automatic** - Claude analyzes dependencies for you
2. **Isolation prevents conflicts** - Each worktree is independent
3. **Dependencies are enforced** - Can't work on blocked subtasks
4. **Merging is safe** - Tests run after each merge to catch integration issues
5. **Speedup is real** - More parallelism = more time saved
