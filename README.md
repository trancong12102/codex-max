# codex-max

Patched `openai/codex` builds for Apple Silicon macOS with higher collaboration defaults and a self-updating `cx` wrapper.

## What This Repository Does

This repository watches upstream `openai/codex` releases, rebuilds the latest release, applies patches, and publishes a GitHub release tagged as `codex-<upstream_tag>`.

Current build target:

- `aarch64-apple-darwin` (Apple Silicon macOS)

Current patch set:

- Collaboration presets model forced to `gpt-5.3-codex`
- Collaboration presets `reasoning_effort` set to `XHigh`
- Collaboration presets `thinking_effort` set to `XHigh` when present upstream
- Explorer built-in model forced to `gpt-5.3-codex`
- Explorer built-in reasoning/thinking effort forced to `xhigh` when present upstream
- Default sub-agent thread limit raised from `6` to `12`

## Install

Remote install:

```bash
curl -fsSL https://raw.githubusercontent.com/trancong12102/codex-max/main/install.sh | bash
```

Local install (from this repository):

```bash
./install.sh
```

Requirements:

- `bash`
- `curl`
- `python3`

If `~/.local/bin` is not on your `PATH`, add it:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

## Usage

Run Codex through the wrapper:

```bash
cx --version
cx <your-args>
```

The wrapper executes:

```bash
codex-max --yolo "$@"
```

## Configuration

`install.sh` variables:

- `BIN_DEST` or `CODEX_MAX_BIN_DEST`: target path for installed binary (default `~/.local/bin/codex-max`)
- `WRAPPER_DEST` or `CODEX_MAX_WRAPPER_DEST`: target path for wrapper (default `~/.local/bin/cx`)
- `DEST`: legacy alias for binary destination

Examples:

```bash
BIN_DEST="$HOME/bin/codex-max" WRAPPER_DEST="$HOME/bin/cx" ./install.sh
```

`cx` wrapper variables:

- `CODEX_MAX_BIN_DEST` or `CODEX_MAX_DEST`: binary path to execute
- `CODEX_MAX_INSTALLER`: local installer path (defaults to `install.sh` next to wrapper)
- `CODEX_MAX_INSTALL_URL`: installer URL fallback when local installer is unavailable
- `CODEX_MAX_WRAPPER_DEST`: wrapper destination during self-update

## Update Behavior

- `install.sh` selects the newest non-draft release in `trancong12102/codex-max` (stable or prerelease, whichever is newest by publish/create timestamp).
- Download is skipped when the binary at `BIN_DEST` already matches the latest release version.
- `cx` attempts to run the installer on every invocation. If update fails but an existing binary is present, it still runs that binary.

## Release Automation

GitHub Actions workflow `.github/workflows/codex-latest-release.yml` runs hourly and on manual dispatch. It:

- Resolves the latest upstream non-draft release from `openai/codex`
- Skips build if `codex-<upstream_tag>` already exists in this repository
- Applies the patch set and builds `codex` for `aarch64-apple-darwin`
- Publishes tarball + sha256 checksum assets

## Limitations

- Only Apple Silicon macOS artifacts are published.
- Patch steps depend on upstream file layout and may require maintenance if upstream refactors.
