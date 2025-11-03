#!/usr/bin/env bash
set -euo pipefail

#===============================================================================
# Script: merge-repo-histories.sh
# Purpose: Merge commit histories from multiple Sablier repositories into the
#          evm-monorepo while preserving all commit metadata (authors, dates)
#
# This script uses git-filter-repo to:
# 1. Clone each source repository
# 2. Rewrite its history to move all files into the appropriate subdirectory
# 3. Merge the rewritten history into the main monorepo
#
# Source repositories:
# - https://github.com/sablier-labs/lockup    -> lockup/
# - https://github.com/sablier-labs/flow      -> flow/
# - https://github.com/sablier-labs/airdrops  -> airdrops/
# - https://github.com/sablier-labs/evm-utils -> utils/
#
# Requirements:
# - git >= 2.36.0
# - python3 >= 3.6
# - git-filter-repo (https://github.com/newren/git-filter-repo)
#===============================================================================

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MONOREPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WORK_DIR="${WORK_DIR:-/tmp/sablier-history-merge}"
DRY_RUN="${DRY_RUN:-false}"
CONTINUE_MODE="${CONTINUE_MODE:-false}"
ABORT_MODE="${ABORT_MODE:-false}"
STATE_FILE="$WORK_DIR/.merge-state"
BACKUP_BRANCH_FILE="$WORK_DIR/.backup-branch"

# Repository mappings: "repo_url subdirectory"
declare -A REPOS=(
  ["lockup"]="https://github.com/sablier-labs/lockup.git"
  ["flow"]="https://github.com/sablier-labs/flow.git"
  ["airdrops"]="https://github.com/sablier-labs/airdrops.git"
  ["utils"]="https://github.com/sablier-labs/evm-utils.git"
)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

#===============================================================================
# Helper Functions
#===============================================================================

log_info() {
  echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $*"
}

check_prerequisites() {
  log_info "Checking prerequisites..."

  # Check git version
  if ! command -v git &> /dev/null; then
    log_error "git is not installed"
    exit 1
  fi

  local git_version
  git_version=$(git --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
  local required_version="2.36.0"

  if ! printf '%s\n%s\n' "$required_version" "$git_version" | sort -V -C; then
    log_error "git version $git_version is too old. Required: >= $required_version"
    exit 1
  fi

  # Check python3
  if ! command -v python3 &> /dev/null; then
    log_error "python3 is not installed"
    exit 1
  fi

  # Check git-filter-repo
  if ! command -v git-filter-repo &> /dev/null; then
    log_error "git-filter-repo is not installed"
    log_info "Install it from: https://github.com/newren/git-filter-repo"
    log_info "On macOS: brew install git-filter-repo"
    exit 1
  fi

  log_success "All prerequisites satisfied"
}

check_clean_working_directory() {
  log_info "Checking working directory status..."

  cd "$MONOREPO_ROOT"

  if [[ -n $(git status --porcelain) ]]; then
    # Check if we're in the middle of a merge
    if [[ -f "$MONOREPO_ROOT/.git/MERGE_HEAD" ]]; then
      log_error "Merge in progress. Please resolve conflicts and run with --continue"
      log_info "To continue: $0 --continue"
      log_info "To abort: git merge --abort"
      exit 1
    fi

    log_error "Working directory is not clean. Please commit or stash changes."
    git status --short
    exit 1
  fi

  log_success "Working directory is clean"
}

cleanup_leftover_remotes() {
  cd "$MONOREPO_ROOT"

  local cleaned=0
  for repo_name in "${!REPOS[@]}"; do
    local remote_name="temp-$repo_name"
    if git remote | grep -q "^${remote_name}$"; then
      git remote remove "$remote_name" 2>/dev/null || true
      ((cleaned++))
    fi
  done

  if [[ $cleaned -gt 0 ]]; then
    log_info "Cleaned up $cleaned leftover remote(s) from previous run"
  fi
}

create_backup_branch() {
  local branch_name="backup-before-history-merge-$(date +%Y%m%d-%H%M%S)"

  log_info "Creating backup branch: $branch_name"

  cd "$MONOREPO_ROOT"
  git branch "$branch_name"

  # Save backup branch name to file for abort
  mkdir -p "$WORK_DIR"
  echo "$branch_name" > "$BACKUP_BRANCH_FILE"

  log_success "Backup branch created: $branch_name"
  echo "To restore: git reset --hard $branch_name"
}

save_backup_branch_name() {
  local branch_name=$1
  mkdir -p "$WORK_DIR"
  echo "$branch_name" > "$BACKUP_BRANCH_FILE"
}

get_backup_branch_name() {
  if [[ -f "$BACKUP_BRANCH_FILE" ]]; then
    cat "$BACKUP_BRANCH_FILE"
  else
    echo ""
  fi
}

setup_work_directory() {
  log_info "Setting up work directory: $WORK_DIR"

  if [[ -d "$WORK_DIR" ]]; then
    if [[ "$CONTINUE_MODE" == "true" ]]; then
      log_info "Reusing existing work directory for continue mode"
    else
      log_warn "Work directory already exists. Removing it..."
      rm -rf "$WORK_DIR"
      mkdir -p "$WORK_DIR"
    fi
  else
    mkdir -p "$WORK_DIR"
  fi

  log_success "Work directory ready"
}

save_state() {
  local current_repo=$1
  local repos_completed=$2

  cat > "$STATE_FILE" <<EOF
CURRENT_REPO=$current_repo
REPOS_COMPLETED=$repos_completed
EOF

  log_info "State saved: processing $current_repo"
}

load_state() {
  if [[ ! -f "$STATE_FILE" ]]; then
    log_error "No state file found at $STATE_FILE"
    log_error "Cannot continue - no previous run to resume"
    exit 1
  fi

  source "$STATE_FILE"
  log_info "Loaded state: resuming from $CURRENT_REPO"
  log_info "Already completed: ${REPOS_COMPLETED:-none}"
}

clear_state() {
  if [[ -f "$STATE_FILE" ]]; then
    rm "$STATE_FILE"
  fi
}

abort_migration() {
  log_warn "Aborting migration and reverting changes..."

  cd "$MONOREPO_ROOT"

  # Check if there's an active merge
  if [[ -f "$MONOREPO_ROOT/.git/MERGE_HEAD" ]]; then
    log_info "Aborting in-progress merge..."
    git merge --abort
    log_success "Merge aborted"
  fi

  # Get backup branch name
  local backup_branch
  backup_branch=$(get_backup_branch_name)

  if [[ -z "$backup_branch" ]]; then
    log_error "No backup branch found!"
    log_warn "Looking for backup branches..."

    # Try to find backup branches
    local branches
    branches=$(git branch | grep "backup-before-history-merge" || true)

    if [[ -n "$branches" ]]; then
      echo ""
      log_info "Found these backup branches:"
      echo "$branches"
      echo ""
      log_info "Please manually reset to one of these branches:"
      log_info "  git reset --hard <branch-name>"
    else
      log_error "No backup branches found. Cannot automatically revert."
    fi
    exit 1
  fi

  # Verify backup branch exists
  if ! git rev-parse --verify "$backup_branch" &>/dev/null; then
    log_error "Backup branch '$backup_branch' not found!"
    exit 1
  fi

  # Show what will be reverted
  log_info "Will reset to backup branch: $backup_branch"
  log_warn "This will discard all changes made during migration"

  # Reset to backup branch
  log_info "Resetting to backup branch..."
  git reset --hard "$backup_branch"
  log_success "Reset to backup branch: $backup_branch"

  # Clean up temp remotes
  log_info "Cleaning up temporary remotes..."
  for repo_name in "${!REPOS[@]}"; do
    local remote_name="temp-$repo_name"
    if git remote | grep -q "^${remote_name}$"; then
      git remote remove "$remote_name"
      log_info "  Removed remote: $remote_name"
    fi
  done

  # Clean up work directory
  log_info "Cleaning up work directory..."
  if [[ -d "$WORK_DIR" ]]; then
    rm -rf "$WORK_DIR"
    log_success "Work directory removed"
  fi

  echo ""
  log_success "Migration aborted successfully!"
  log_info "Repository has been restored to: $backup_branch"
  log_info "You can delete the backup branch later with:"
  log_info "  git branch -d $backup_branch"
}

clone_and_prepare_repo() {
  local repo_name=$1
  local repo_url=$2
  local target_dir=$3

  log_info "Processing repository: $repo_name" >&2

  local clone_dir="$WORK_DIR/${repo_name}-temp"

  # Clone the repository
  log_info "  Cloning $repo_url..." >&2
  git clone --bare "$repo_url" "$clone_dir" >&2

  cd "$clone_dir"

  # Rewrite history to move everything into subdirectory
  log_info "  Rewriting history to move files into $target_dir/..." >&2
  git-filter-repo \
    --to-subdirectory-filter "$target_dir" \
    --force \
    --quiet >&2

  log_success "  Repository $repo_name prepared" >&2

  # Return the path (stdout only)
  echo "$clone_dir"
}

merge_repo_into_monorepo() {
  local repo_name=$1
  local prepared_repo_path=$2

  log_info "Merging $repo_name history into monorepo..."

  cd "$MONOREPO_ROOT"

  # Add the prepared repository as a remote
  local remote_name="temp-$repo_name"

  # Remove remote if it already exists (from failed previous run)
  if git remote | grep -q "^${remote_name}$"; then
    log_warn "  Removing existing remote '$remote_name' from previous run..."
    git remote remove "$remote_name"
  fi

  git remote add "$remote_name" "$prepared_repo_path"

  # Fetch all branches (skip tags as we only need commit history)
  log_info "  Fetching branches..."
  git fetch "$remote_name" --no-tags

  # Get the main branch SHA directly from the remote
  local main_sha
  main_sha=$(git ls-remote "$remote_name" refs/heads/main | awk '{print $1}')

  if [[ -z "$main_sha" ]]; then
    log_error "Could not find main branch SHA in remote"
    return 1
  fi

  log_info "  Main branch SHA: $main_sha"

  # Merge the history with --allow-unrelated-histories using the SHA
  log_info "  Merging main branch..."
  if git merge "$main_sha" \
    --allow-unrelated-histories \
    --no-edit \
    -m "chore: merge history from $repo_name repository

This merge incorporates the full commit history from the $repo_name
repository while preserving all commit metadata (authors, timestamps).

All files have been moved to the $repo_name/ subdirectory.

Source: ${REPOS[$repo_name]}"; then
    # Merge succeeded
    log_success "  Merged $repo_name successfully"

    # Remove old config files that shouldn't be in monorepo
    log_info "  Removing old config files from $repo_name/"
    local config_files=(
      ".editorconfig"
      ".env.example"
      ".github"
      ".gitignore"
      ".husky"
      ".lintstagedrc.js"
      ".prettierignore"
      ".prettierrc.js"
      ".solhint.json"
      ".vscode"
      "CONTRIBUTING.md"
      "LICENSE-BUSL.md"
      "LICENSE-GPL.md"
      "LICENSE.md"
      "SECURITY.md"
      "codecov.yml"
      "funding.json"
      "repomix.config.jsonc"
      "slither.config.json"
    )

    local files_to_remove=()
    for file in "${config_files[@]}"; do
      if [[ -e "$repo_name/$file" ]]; then
        files_to_remove+=("$repo_name/$file")
      fi
    done

    if [[ ${#files_to_remove[@]} -gt 0 ]]; then
      git rm -rf "${files_to_remove[@]}" >/dev/null 2>&1
      git commit -m "chore: remove old config files from $repo_name

These files were part of the standalone repository but are not needed
in the monorepo structure." --no-verify
      log_success "  Removed ${#files_to_remove[@]} config file(s)"
    fi

    # Remove the temporary remote
    git remote remove "$remote_name"

    return 0
  else
    # Merge failed (conflicts) - automatically resolve with "ours" strategy
    log_warn "Merge conflicts detected - auto-resolving with 'ours' strategy..."

    # Get list of conflicted files
    local conflicted_files
    conflicted_files=$(git diff --name-only --diff-filter=U)

    if [[ -z "$conflicted_files" ]]; then
      log_error "No conflicted files found, but merge failed"
      return 1
    fi

    log_info "  Resolving conflicts in:"
    echo "$conflicted_files" | while read -r file; do
      log_info "    - $file"
    done

    # Resolve all conflicts with "ours" strategy
    echo "$conflicted_files" | xargs git checkout --ours

    # Stage all files in the subdirectory
    git add "$repo_name/"

    # Complete the merge
    if git commit --no-edit; then
      log_success "  Conflicts resolved and merge completed"

      # Remove old config files that shouldn't be in monorepo
      log_info "  Removing old config files from $repo_name/"
      local config_files=(
        ".editorconfig"
        ".env.example"
        ".github"
        ".gitignore"
        ".husky"
        ".lintstagedrc.js"
        ".prettierignore"
        ".prettierrc.js"
        ".solhint.json"
        ".vscode"
        "CONTRIBUTING.md"
        "LICENSE-BUSL.md"
        "LICENSE-GPL.md"
        "LICENSE.md"
        "SECURITY.md"
        "codecov.yml"
        "funding.json"
        "repomix.config.jsonc"
        "slither.config.json"
      )

      local files_to_remove=()
      for file in "${config_files[@]}"; do
        if [[ -e "$repo_name/$file" ]]; then
          files_to_remove+=("$repo_name/$file")
        fi
      done

      if [[ ${#files_to_remove[@]} -gt 0 ]]; then
        git rm -rf "${files_to_remove[@]}" >/dev/null 2>&1
        git commit -m "chore: remove old config files from $repo_name

These files were part of the standalone repository but are not needed
in the monorepo structure." --no-verify
        log_success "  Removed ${#files_to_remove[@]} config file(s)"
      fi

      # Remove the temporary remote
      git remote remove "$remote_name"

      return 0
    else
      log_error "Failed to commit after resolving conflicts"
      return 1
    fi
  fi
}

continue_after_conflicts() {
  local repo_name=$1

  log_info "Continuing merge for $repo_name..."

  cd "$MONOREPO_ROOT"

  # Check if merge is complete
  if [[ ! -f "$MONOREPO_ROOT/.git/MERGE_HEAD" ]]; then
    log_error "No merge in progress for $repo_name"
    return 1
  fi

  # Check if there are still unresolved conflicts
  if git status --porcelain | grep -q '^UU\|^AA\|^DD'; then
    log_error "Unresolved conflicts still exist. Please resolve all conflicts first."
    git status --short
    return 1
  fi

  # Check if changes are staged
  if ! git diff --cached --quiet; then
    log_info "  Committing resolved merge..."
    git commit --no-edit || {
      log_error "Failed to commit merge"
      return 1
    }
    log_success "  Merge committed successfully"
  else
    log_error "No changes staged. Please stage resolved files with: git add <file>"
    return 1
  fi

  # Clean up the remote
  local remote_name="temp-$repo_name"
  if git remote | grep -q "^${remote_name}$"; then
    git remote remove "$remote_name"
  fi

  log_success "  Completed $repo_name merge"
  return 0
}

cleanup_work_directory() {
  if [[ "$DRY_RUN" == "false" ]]; then
    log_info "Cleaning up work directory..."
    rm -rf "$WORK_DIR"
    log_success "Cleanup complete"
  else
    log_info "Dry run: keeping work directory at $WORK_DIR"
  fi
}

print_summary() {
  log_info "Migration summary:"

  cd "$MONOREPO_ROOT"

  echo ""
  echo "Total commits in monorepo:"
  git rev-list --count HEAD

  echo ""
  echo "Commits by repository (approximate - based on file paths):"
  for repo_name in "${!REPOS[@]}"; do
    local count
    count=$(git rev-list --all --count -- "$repo_name/" 2>/dev/null || echo "0")
    echo "  $repo_name: $count commits"
  done

  echo ""
  echo "Recent commits:"
  git log --oneline --graph --all -20
}

#===============================================================================
# Main Execution
#===============================================================================

main() {
  # Handle abort mode first
  if [[ "$ABORT_MODE" == "true" ]]; then
    abort_migration
    return 0
  fi

  log_info "Starting repository history merge process..."
  log_info "Monorepo: $MONOREPO_ROOT"
  log_info "Work directory: $WORK_DIR"

  if [[ "$DRY_RUN" == "true" ]]; then
    log_warn "DRY RUN MODE - no changes will be committed to monorepo"
  fi

  if [[ "$CONTINUE_MODE" == "true" ]]; then
    log_warn "CONTINUE MODE - resuming from previous run"
  fi

  echo ""

  # Prerequisite checks
  check_prerequisites

  if [[ "$CONTINUE_MODE" == "false" ]]; then
    check_clean_working_directory
    cleanup_leftover_remotes

    # Create backup
    if [[ "$DRY_RUN" == "false" ]]; then
      create_backup_branch
    fi
  fi

  # Setup
  setup_work_directory

  # Determine which repos to process
  local repos_completed=""
  local current_repo=""
  local skip_until_found=false

  if [[ "$CONTINUE_MODE" == "true" ]]; then
    load_state
    repos_completed="$REPOS_COMPLETED"
    current_repo="$CURRENT_REPO"
    skip_until_found=true
    log_info "Will resume at: $current_repo"
  fi

  # Process each repository
  for repo_name in "${!REPOS[@]}"; do
    # Skip already completed repos in continue mode
    if [[ "$CONTINUE_MODE" == "true" ]] && [[ "$skip_until_found" == "true" ]]; then
      if [[ "$repo_name" != "$current_repo" ]]; then
        log_info "Skipping already completed: $repo_name"
        continue
      else
        skip_until_found=false
        log_info "Resuming at: $repo_name"

        # Continue the merge that was in progress
        if [[ -f "$MONOREPO_ROOT/.git/MERGE_HEAD" ]]; then
          if ! continue_after_conflicts "$repo_name"; then
            log_error "Failed to complete merge for $repo_name"
            save_state "$repo_name" "$repos_completed"
            exit 1
          fi
          # Mark as completed and move to next
          repos_completed="$repos_completed $repo_name"
          save_state "" "$repos_completed"
          continue
        fi
      fi
    fi

    echo ""
    log_info "=========================================="
    log_info "Processing: $repo_name"
    log_info "=========================================="

    local repo_url="${REPOS[$repo_name]}"
    local prepared_repo

    # Check if repo is already prepared (from previous run)
    local expected_path="$WORK_DIR/${repo_name}-temp"
    if [[ -d "$expected_path" ]]; then
      log_info "Using pre prepared repository from previous run"
      prepared_repo="$expected_path"
    else
      # Clone and prepare the repository
      prepared_repo=$(clone_and_prepare_repo "$repo_name" "$repo_url" "$repo_name")
    fi

    # Save state before merging
    save_state "$repo_name" "$repos_completed"

    # Merge into monorepo
    if [[ "$DRY_RUN" == "false" ]]; then
      if ! merge_repo_into_monorepo "$repo_name" "$prepared_repo"; then
        log_error "Migration paused due to merge conflicts"
        exit 1
      fi
      repos_completed="$repos_completed $repo_name"
    else
      log_warn "Dry run: skipping merge for $repo_name"
    fi
  done

  # Cleanup
  cleanup_work_directory
  clear_state

  # Print summary
  echo ""
  log_info "=========================================="
  log_info "Migration Complete!"
  log_info "=========================================="
  echo ""

  if [[ "$DRY_RUN" == "false" ]]; then
    print_summary

    echo ""
    log_success "All repository histories have been merged!"
    log_warn "IMPORTANT: Review the changes before pushing to remote"
    log_info "To push: git push origin main --force"
    log_info "To rollback: Look for the backup branch created earlier"
  else
    log_warn "This was a dry run. No changes were made to the monorepo."
    log_info "Prepared repositories are available in: $WORK_DIR"
    log_info "To run for real, execute: DRY_RUN=false $0"
  fi
}

#===============================================================================
# Script Entry Point
#===============================================================================

# Handle script arguments
case "${1:-}" in
  --help|-h)
    cat << EOF
Usage: $0 [OPTIONS]

Merge commit histories from Sablier repositories into the evm-monorepo.

OPTIONS:
  --help, -h          Show this help message
  --dry-run           Run without making changes to the monorepo
  --continue          Continue from a previous run after resolving conflicts
  --abort             Abort the migration and revert all changes

ENVIRONMENT VARIABLES:
  DRY_RUN=true        Same as --dry-run flag
  WORK_DIR=/path      Override the work directory (default: /tmp/sablier-history-merge)

EXAMPLES:
  # Dry run to test the process
  $0 --dry-run

  # Or using environment variable
  DRY_RUN=true $0

  # Actual migration
  $0

REQUIREMENTS:
  - git >= 2.36.0
  - python3 >= 3.6
  - git-filter-repo (install via: brew install git-filter-repo)

IMPORTANT:
  - Make sure you have a clean working directory
  - This script will create a backup branch automatically
  - Review changes before pushing to remote
  - The process may take several minutes depending on repository sizes

EOF
    exit 0
    ;;
  --dry-run)
    DRY_RUN=true
    ;;
  --continue)
    CONTINUE_MODE=true
    ;;
  --abort)
    ABORT_MODE=true
    ;;
esac

# Run the main function
main
