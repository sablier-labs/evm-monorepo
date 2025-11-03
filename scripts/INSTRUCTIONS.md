# Repository History Merge

Merges commit history from the original Sablier repositories into the evm-monorepo while preserving all metadata.

## Prerequisites

- [Git](https://git-scm.com) (v2.36+)
- [Python 3](https://python.org) (v3.6+)
- [git-filter-repo](https://github.com/newren/git-filter-repo)

Install git-filter-repo:

```shell
brew install git-filter-repo
```

## Usage

Dry run (recommended first):

```shell
./scripts/merge-repo-histories.sh --dry-run
```

Run the migration:

```shell
./scripts/merge-repo-histories.sh
```

Abort and revert if needed:

```shell
./scripts/merge-repo-histories.sh --abort
```

## What It Does

1. Creates a backup branch automatically
2. Clones each source repository (lockup, flow, airdrops, evm-utils)
3. Rewrites history to move files into subdirectories
4. Merges into monorepo preserving all commit metadata
5. Auto-resolves conflicts using "ours" strategy

## After Running

Review the changes:

```shell
git log --oneline --graph -50
git log --oneline -- lockup/
```

Push when ready:

```shell
git push origin main --force
```

Rollback if needed:

```shell
git branch | grep backup-before-history-merge
git reset --hard backup-before-history-merge-YYYYMMDD-HHMMSS
```
