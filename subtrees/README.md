# Vendored Subtrees

This directory contains external product repositories embedded via [`git subtree`](https://git-scm.com). 

These directories are included directly in this repository so developers and users can clone and build packages locally with a single `git clone`—no submodule initialization or extra authentication required.

## Contributor & Pull Request Policy

* **Do not edit files inside any subdirectory here directly.** Treat every subdirectory under `subtrees/` as read-only upstream code.
* **Automated PR Validation:** Any Pull Request that modifies files inside a `subtrees/<name>/` directory without using a proper `git subtree add` or `git subtree pull` command will **automatically fail CI validation** (`.github/workflows/validate-subtree.yml`).
* **Where to make product changes:** Submit fixes or features to the upstream repository listed in the manifest below first, then pull those changes into this repo using the subtree workflow.
* **Merging subtree PRs:** Maintainers must merge subtree update PRs using a **standard merge commit** (do **not** use *Squash and merge*, as squashing strips the `git-subtree-*` commit trailers required for future pulls).

---

## Subtree Manifest

| Directory | Upstream Repository | Tracked Branch / Tag | Purpose |
| :--- | :--- | :--- | :--- |
| `subtrees/quisk` | `https://github.com/visierl/quisk` | `dev` | Custom Quisk SDR front-end fork |

---

## Maintainer Commands

> **Important:** Never include a trailing slash on `--prefix` (use `subtrees/quisk`, not `subtrees/quisk/`), or the CI validation check will reject the commit trailer.

### Syncing via Helper Script
```bash
./scripts/subtree-sync.sh --dry-run   # Preview commands
./scripts/subtree-sync.sh             # Add or pull all subtrees in manifest
```

### Manual Commands
```bash
# Add a new subtree
git subtree add --prefix=subtrees/<name> <repository-url> <branch-or-tag> --squash

# Pull updates into an existing subtree
git subtree pull --prefix=subtrees/<name> <repository-url> <branch-or-tag> --squash
```
