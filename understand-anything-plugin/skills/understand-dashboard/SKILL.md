---
name: understand-dashboard
description: Launch the interactive web dashboard to visualize a codebase's knowledge graph
argument-hint: [project-path]
---

# /understand-dashboard

Start the Understand Anything dashboard to visualize the knowledge graph for the current project.

## Instructions

1. Determine the project directory:
   - If `$ARGUMENTS` contains a path, use that as the project directory
   - Otherwise, use the current working directory

2. Check that `.understand-anything/knowledge-graph.json` exists in the project directory. If not, tell the user:
   ```
   No knowledge graph found. Run /understand first to analyze this project.
   ```

3. Find the dashboard code. The dashboard is at `packages/dashboard/` relative to this plugin's root directory. Resolve paths from environment variables first, then fall back to the OpenClaw workspace defaults.

   Use the Bash tool to resolve:
   ```bash
   REPO_CHECKOUT="${UA_REPO_DIR:-${UA_DIR:-$HOME/.openclaw/workspace/.understand-anything/repo}}"

   PLUGIN_ROOT=""
   for candidate in \
     "${UA_PLUGIN_DIR:-}" \
     "${CLAUDE_PLUGIN_ROOT:-}" \
     "$HOME/.openclaw/workspace/.understand-anything-plugin" \
     "$REPO_CHECKOUT/understand-anything-plugin"; do
     if [ -n "$candidate" ] && [ -d "$candidate/packages/dashboard" ]; then
       PLUGIN_ROOT="$candidate"
       break
     fi
   done

   if [ -z "$PLUGIN_ROOT" ]; then
     echo "Error: Cannot find the understand-anything plugin root."
     echo "Checked:"
     echo "  - ${UA_PLUGIN_DIR:-<unset UA_PLUGIN_DIR>}"
     echo "  - ${CLAUDE_PLUGIN_ROOT:-<unset CLAUDE_PLUGIN_ROOT>}"
     echo "  - $HOME/.openclaw/workspace/.understand-anything-plugin"
     echo "  - $REPO_CHECKOUT/understand-anything-plugin"
     echo "Set UA_PLUGIN_DIR if you installed the plugin to a custom location."
     exit 1
   fi
   ```

4. Install dependencies and build if needed:
   ```bash
   cd <dashboard-dir> && pnpm install --frozen-lockfile 2>/dev/null || pnpm install
   ```
   Then ensure the core package is built (the dashboard depends on it):
   ```bash
   cd <plugin-root> && pnpm --filter @understand-anything/core build
   ```

5. Start the Vite dev server pointing at the project's knowledge graph:
   ```bash
   cd <dashboard-dir> && GRAPH_DIR=<project-dir> npx vite --host 127.0.0.1
   ```
   Run this in the background so the user can continue working.

6. **Capture the access token URL from the server output.** The Vite server prints a line like:
   ```
   🔑  Dashboard URL: http://127.0.0.1:<PORT>?token=<TOKEN>
   ```
   Extract the full URL including the `?token=` parameter. The token is required to access the knowledge graph data — without it the dashboard will show an "Access Token Required" gate.

7. Report to the user, including the full tokenized URL:
   ```
   Dashboard started at http://127.0.0.1:<PORT>?token=<TOKEN>
   Viewing: <project-dir>/.understand-anything/knowledge-graph.json

   The dashboard is running in the background. Press Ctrl+C in the terminal to stop it.
   ```
   **Important:** Always include the `?token=` parameter in the URL you share. If you omit it, the user will be blocked by the token gate and have to manually find the token in the terminal output.

## Notes

- The dashboard auto-opens in the default browser via `--open`
- If port 5173 is already in use, Vite will pick the next available port
- The `GRAPH_DIR` environment variable tells the dashboard where to find the knowledge graph
