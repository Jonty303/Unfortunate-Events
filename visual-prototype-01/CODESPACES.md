# Codespaces - Touch + Web prototype

The complete project and artwork are committed to `visual-prototype-01` in `Jonty303/Unfortunate-Events`. No ZIP upload is required.

## 1. Pull the correct branch

Return to the repository first; the earlier installation commands may have left the terminal in `/tmp`.

```bash
cd /workspaces/Unfortunate-Events
git status
```

Preserve any local changes before switching branches. Then:

```bash
git fetch origin &&
git switch visual-prototype-01 &&
git pull --ff-only origin visual-prototype-01 &&
cd visual-prototype-01
```

The project is `visual-prototype-01/project.godot`, not `initial prototype/project.godot`.

## 2. Install Godot only if needed

For a fresh Codespace:

```bash
sudo apt-get update
sudo apt-get install -y curl unzip python3 ca-certificates
bash tools/install_godot.sh
```

The installer pins standard Godot 4.5.2, verifies SHA-256 checksums, installs a versioned executable at `~/.local/bin/godot-4.5.2`, and installs matching Web templates. The official all-platform template archive is about 1.35 GB; only Web templates are extracted. It does not replace an existing `godot` command.

An existing installation from the earlier commands can be reused:

```bash
"$HOME/.local/bin/godot" --headless --version
GODOT_BIN="$HOME/.local/bin/godot" bash tools/export_web.sh
```

That executable must report `4.5.2.stable...` and matching Web templates must be installed. A version mismatch is deliberately rejected.

## 3. Build

With the versioned installer above:

```bash
bash tools/export_web.sh
```

This imports assets, runs `tests/touch_smoke.gd`, checks errors in `build/logs/`, and exports to `build/web/index.html`. A successful touch suite prints `TOUCH TESTS PASSED`. Stop and inspect the log if a stage fails.

## 4. Serve and open in the browser

```bash
python3 tools/serve_web.py --port 8080
```

Keep that terminal running. Open the Codespaces Ports panel, forward 8080 if needed, and choose Open in Browser. Use the HTTPS forwarded URL in a full Safari/browser tab, not the editor's embedded preview. The server exposes only `build/web`, not the repository. Keep the port Private for your own signed-in testing.

For deliberately public sharing, use a second terminal:

```bash
gh codespace ports visibility 8080:public -c "$CODESPACE_NAME"
```

Return it to private with:

```bash
gh codespace ports visibility 8080:private -c "$CODESPACE_NAME"
```

Organisation policy may restrict public ports. This is temporary hosting: the Codespace and server must stay running. Ctrl+C stops the server. No publishing, port-visibility changes or Git pushes are performed by the local build scripts.

## 5. iPad check and iteration

Use landscape orientation. In AUTO mode the controls should appear; the top-right selector can force ON. Steer while holding FIRE, then add ROCKET with a third finger. Check releases, dragging off buttons, pause/resume, restart, rotation and switching away from the tab. Real iPad input and performance still require device validation.

The Web preset uses Compatibility/WebGL 2, single-threaded export, disabled PWA caching and touch-action suppression on the canvas. Controls do not change the gameplay bounds. To iterate: stop the server, pull changes, rebuild, restart the server and reload the testing tab.

## References

- https://godotengine.org/download/archive/4.5.2-stable/
- https://docs.godotengine.org/en/4.5/tutorials/editor/command_line_tutorial.html
- https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_web.html
- https://docs.github.com/en/codespaces/developing-in-a-codespace/forwarding-ports-in-your-codespace
- https://cli.github.com/manual/gh_codespace_ports_visibility
