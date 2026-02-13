---
description: Beru AI Agent Integration - enables Cursor to delegate computer tasks to Beru, an autonomous AI running 24/7 on a Mac Mini
globs:
alwaysApply: true
---

# Beru Integration

## Who Beru Is

Beru is an autonomous AI agent (OpenClaw/ClawdBot) running 24/7 on Cruce's Mac Mini (Tailscale IP: 100.65.244.100). Beru has FULL CONTROL of that computer — browser, GUI apps, terminal, file system, Xcode, Simulator, everything. Think of Beru as a human colleague sitting at the Mac Mini who can do anything a person with computer access could do.

Beru has:
- Full browser control (can log into accounts, set up services, navigate UIs)
- Xcode and iOS Simulator access (can build, test, take screenshots)
- Terminal and file system access on the Mac Mini
- Persistent memory across sessions (remembers past work and context)
- Telegram notifications to Cruce when completing significant tasks

IMPORTANT: You (Cursor) are on Cruce's MacBook. Beru is on the Mac Mini. These are different machines connected via Tailscale. You cannot directly access the Mac Mini's file system or GUI — you communicate with Beru through the methods described below.

NOTE: There is also an OpenClaw agent called "Carson" on this MacBook. Do NOT confuse them. When using the `openclaw` CLI on this machine, it routes to Carson, NOT Beru. To reach Beru, use the methods below.

## When to Delegate to Beru

### You (Cursor) handle:
- All code editing, file creation, refactoring
- Architecture decisions, planning, code review
- Git operations on the MacBook (add, commit, push, pull)
- Reading/writing files in the project
- Running local terminal commands

### Delegate to Beru when the task requires:
- Browser interaction (logging into Firebase, Vercel, GitHub web UI, any account)
- Setting up external services (Firebase, Vercel, Supabase, AWS, etc.)
- Xcode building, archiving, or Simulator testing
- Taking screenshots of running apps or UIs
- TestFlight uploads
- Any GUI application interaction
- Visual verification of anything
- Creating GitHub repositories (Beru uses `gh` CLI on Mac Mini)
- Any task that requires a human at a computer

### When unsure:
Ask Beru. Describe what you need and he'll tell you honestly whether he can do it.

## How to Communicate with Beru

### Primary Method: MCP Tools (when available)

If Beru's MCP tools appear in your tool list (tools prefixed with `beru_`), use them directly. This is the native, preferred method.

### Fallback Method: HTTP via curl

If MCP tools are not available, use curl to reach Beru's task endpoint:

```bash
curl -s -X POST http://100.65.244.100:3100/task \
  -H "Content-Type: application/json" \
  -d '{
    "task": "YOUR NATURAL LANGUAGE REQUEST HERE",
    "project": "PROJECT NAME (optional)",
    "context": "ADDITIONAL CONTEXT (optional)",
    "repo_url": "GITHUB REPO URL (if code-related)",
    "commit_sha": "LATEST COMMIT SHA (if code-related)"
  }'
```

For multi-turn conversations (follow-ups, clarification), include a session_id:

```bash
curl -s -X POST http://100.65.244.100:3100/task \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "PROJECT-NAME-task-description",
    "task": "Follow-up: the config file you mentioned — where exactly did you put it?"
  }'
```

### Emergency Fallback: Direct openclaw via SSH

If Beru's HTTP server is down, SSH to Mac Mini and use openclaw directly:

```bash
ssh crucegauntlet@100.65.244.100 'openclaw agent --session-id cursor-PROJECT --message "YOUR REQUEST" --json'
```

Note: SSH passwordless access may need to be configured first.

### Communication Style

- Write in natural language, like you're talking to a competent colleague
- Include full context: what project, what you're building, why you need this, what you've already done
- Do NOT use rigid JSON schemas or fixed tool formats — Beru understands natural language
- For complex tasks, have multi-turn conversations: ask, get response, follow up
- If Beru's response is unclear or incomplete, ask for clarification

## Git as the Code Bridge

Since you (MacBook) and Beru (Mac Mini) are on different machines, Git is how code stays in sync.

### Before delegating any task that requires Beru to have the current codebase:
1. Stage and commit all current changes: `git add . && git commit -m "sync: [brief description]"`
2. Push to remote: `git push`
3. Include the repo URL and commit SHA in your request to Beru

### If this is a brand new project with no Git repo:
1. Ask Beru to create a private GitHub repo: include the project name and description
2. Once Beru returns the repo URL, initialize locally:
   ```bash
   git init
   git remote add origin [REPO_URL]
   git add .
   git commit -m "Initial commit"
   git push -u origin main
   ```

### After Beru makes code changes:
- Beru will commit and push to the repo from Mac Mini
- Pull changes locally: `git pull`

### Getting the current commit SHA:
```bash
git rev-parse HEAD
```

### Getting the repo URL:
```bash
git remote get-url origin
```

## Verification and Feedback

After every delegation to Beru:
1. Check the result — did Beru say it was successful?
2. If the task involved code changes: `git pull` and verify the files
3. If the task involved service setup: verify by checking config files, env vars, or asking Beru to confirm
4. If something seems wrong: follow up with Beru, ask questions, iterate
5. Do NOT blindly trust a single response for critical tasks — verify

## Transparency to the User

ALWAYS tell Cruce:
- BEFORE delegating: "I'm going to ask Beru to [task] because [reason]."
- AFTER receiving results: "Beru reports: [summary of what was done]."
- If delegating multiple tasks: clearly list what you're doing yourself vs. what Beru is handling
- If Beru encounters an error or can't complete something: report it immediately

## Proactive Collaboration

Do NOT treat Beru as a rigid tool with fixed capabilities. Beru is a general-purpose AI agent. Be creative about delegation:
- If you're unsure about a UI layout, ask Beru to take a screenshot after building
- If you need to verify an API key works, ask Beru to test it in browser
- If you're setting up a complex service, have a conversation with Beru about the best approach
- If you need information from a web dashboard, ask Beru to check and report back
- If something needs debugging that requires visual inspection, delegate to Beru

Think of the relationship as: you are the technical lead doing the code, Beru is your capable assistant who handles everything that requires hands on a computer.
