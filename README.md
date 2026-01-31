# codex-max

Patched Codex CLI builds with higher reasoning presets, published as GitHub releases and installable via a single script.

This repo tracks the latest **alpha** releases of `openai/codex`, applies a patch that sets the collaboration-mode reasoning presets to `XHigh`, then publishes a patched binary for Apple Silicon macOS.

## What this changes

- Upstream: `openai/codex` alpha releases
- Patch: `reasoning_effort` presets for Plan / Pair Programming / Execute set to `XHigh`
- Target: `aarch64-apple-darwin` (Apple Silicon macOS)

## Install

Use the installer script included in this repo. It will:

- Query the latest GitHub release
- Compare against your installed codex-max binary version
- Download only if you are not already on the latest release
- Install the wrapper to `~/.local/bin/cx` (default)
- Install the patched binary to `~/.local/bin/codex-max` (default)

```bash
curl -fsSL https://raw.githubusercontent.com/trancong12102/codex-max/main/install.sh | bash
```

If you already cloned this repo, you can run it locally:

```bash
./install.sh
```

Optional: override the installed binary path.

```bash
BIN_DEST="$HOME/bin/codex-max" ./install.sh
```

Optional: override the wrapper path.

```bash
WRAPPER_DEST="$HOME/bin/cx" ./install.sh
```

If `~/.local/bin` is not on your `PATH`, add it (e.g. in `~/.zshrc`):

```bash
export PATH="$HOME/.local/bin:$PATH"
```

## Wrapper (auto-update on run)

The installed `cx` wrapper checks for the latest codex-max release on each run, installs it to the configured binary path, then forwards all arguments to the patched CLI.

## Verify

```bash
cx --version
```

## Notes

- Releases are tagged as `codex-<upstream_tag>` and marked as prerelease.
- Only Apple Silicon macOS artifacts are produced by the current workflow.
