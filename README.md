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
- Compare against your installed `codex` version
- Download only if you are not already on the latest release
- Extract and install to `~/.local/bin/codex` (default)

```bash
curl -fsSL https://raw.githubusercontent.com/trancong12102/codex-max/main/install-codex.sh | bash
```

If you already cloned this repo, you can run it locally:

```bash
./install-codex.sh
```

Optional: override the destination path.

```bash
DEST="$HOME/bin/codex" ./install-codex.sh
```

If `~/.local/bin` is not on your `PATH`, add it (e.g. in `~/.zshrc`):

```bash
export PATH="$HOME/.local/bin:$PATH"
```

## Verify

```bash
codex --version
```

## Notes

- Releases are tagged as `codex-<upstream_tag>` and marked as prerelease.
- Only Apple Silicon macOS artifacts are produced by the current workflow.
