#!/usr/bin/env bash

# Что делает:
#   1. Поднимает remote на upstream (tgstation/tgstation).
#   2. Пересоздаёт ветку merge-upstream, делая её точной копией upstream/master.
#   3. Находит все коммиты upstream, которых ещё нет в нашем master.
#   4. Из этих коммитов собирает changelog (формат :cl:), переиспользуя changelog-ключи Nemesis, и складывает его в тело PR.
#   5. Создаёт (или обновляет) PR "merge-upstream -> master".
#
# Переменные окружения:
#   TARGET_REPO - репозиторий-приёмник (default: $GITHUB_REPOSITORY || ss220-space/Nemesis)
#   TARGET_BRANCH - ветка-приёмник (default: master)
#   UPSTREAM_REPO - апстрим (default: tgstation/tgstation)
#   UPSTREAM_BRANCH - ветка апстрима (default: master)
#   MERGE_BRANCH - служебная ветка для PR (default: merge-upstream)
#   CHANGELOG_AUTHOR - автор в :cl: блоке (default: tgstation)
#   MAX_PRS - предел PR для сбора changelog (default: 400, 0 = без лимита)
#   GH_TOKEN - токен для gh/git (в CI - токен CHANGELOGBOT app)
#
# Требует: git, gh, jq.

set -u # error on use of an uninitialized variable
set -o pipefail

readonly TARGET_REPO="${TARGET_REPO:-${GITHUB_REPOSITORY:-ss220-space/Nemesis}}"
readonly TARGET_BRANCH="${TARGET_BRANCH:-master}"
readonly UPSTREAM_REPO="${UPSTREAM_REPO:-tgstation/tgstation}"
readonly UPSTREAM_BRANCH="${UPSTREAM_BRANCH:-master}"
readonly MERGE_BRANCH="${MERGE_BRANCH:-merge-upstream}"
readonly CHANGELOG_AUTHOR="${CHANGELOG_AUTHOR:-tgstation}"
readonly MAX_PRS="${MAX_PRS:-400}"

log() { echo "[merge_upstream] $*"; }
die() { echo "[merge_upstream] ERROR: $*" >&2; exit 1; }

# --- Environment checks ---------------------------------------------------

[ -d .git ] || die "must be run from the root of a git repository"
type git >/dev/null 2>&1 || die "git is required"
type gh  >/dev/null 2>&1 || die "gh (GitHub CLI) is required"
type jq  >/dev/null 2>&1 || die "jq is required"

# --- Remote setup ---------------------------------------------------------

if ! git remote | grep -qx upstream; then
  log "Adding upstream remote -> https://github.com/${UPSTREAM_REPO}.git"
  git remote add upstream "https://github.com/${UPSTREAM_REPO}.git"
else
  git remote set-url upstream "https://github.com/${UPSTREAM_REPO}.git"
fi

log "Fetching upstream (${UPSTREAM_REPO}@${UPSTREAM_BRANCH})..."
git fetch --no-tags upstream "${UPSTREAM_BRANCH}" || die "failed to fetch upstream"
git fetch --no-tags origin || die "failed to fetch origin"

# --- Recreate the merge-upstream branch -----------------------------------

if git ls-remote --exit-code --heads origin "${MERGE_BRANCH}" >/dev/null 2>&1; then
  log "Branch ${MERGE_BRANCH} exists, resetting it to upstream/${UPSTREAM_BRANCH}"
  git checkout -f -B "${MERGE_BRANCH}" "upstream/${UPSTREAM_BRANCH}"
  git push --force origin "${MERGE_BRANCH}"
else
  log "Creating branch ${MERGE_BRANCH} from upstream/${UPSTREAM_BRANCH}"
  git checkout -f -B "${MERGE_BRANCH}" "upstream/${UPSTREAM_BRANCH}"
  git push -u origin "${MERGE_BRANCH}"
fi

# --- Detect new commits and PR numbers ------------------------------------

log "Detecting upstream commits not present in ${TARGET_BRANCH}..."
# Chronological order (old -> new) so the changelog follows merge order.
mapfile -t COMMIT_LOG < <(git log --reverse --pretty=format:'%s' \
  "origin/${TARGET_BRANCH}..${MERGE_BRANCH}")

if [ "${#COMMIT_LOG[@]}" -eq 0 ]; then
  log "No new commits — Nemesis is already in sync with ${UPSTREAM_REPO}. Exiting."
  exit 0
fi

# Collect unique PR numbers from commit subjects like "Title (#12345)".
declare -A SEEN_PR=()
PR_NUMBERS=()
for subject in "${COMMIT_LOG[@]}"; do
  case "$subject" in
    *"[ci skip]"*) continue ;;
  esac
  num="$(printf '%s\n' "$subject" | grep -oE '#[0-9]+' | head -n1 | tr -d '#')"
  [ -n "${num:-}" ] || continue
  if [ -z "${SEEN_PR[$num]:-}" ]; then
    SEEN_PR[$num]=1
    PR_NUMBERS+=("$num")
  fi
done

log "Found new upstream PRs: ${#PR_NUMBERS[@]}"

# --- Collect changelog from PR bodies -------------------------------------

# Extracts changelog lines (key: description) from the :cl: block of a PR body.
# Reuses the same tag format as tools/pull_request_hooks/changelogConfig.js.
extract_changelog() {
  awk '
    function ltrim(s){ sub(/^[ \t\r]+/, "", s); return s }
    function rtrim(s){ sub(/[ \t\r]+$/, "", s); return s }
    {
      line = rtrim($0)
      t = ltrim(line)
      if (!incl) {
        if (t ~ /^:cl:/ || t ~ /^\?\?/) { incl = 1 }
        next
      }
      if (t ~ /^\/:cl:/ || t ~ /^\/ :cl:/ || t ~ /^:\/cl:/ || t ~ /^\/\?\?/ || t ~ /^\/ \?\?/) { incl = 0; next }
      if (t ~ /^[A-Za-z_]+:[ \t]+.+/) { print t }
    }
  '
}

CHANGELOG_LINES=()
collected=0
for num in "${PR_NUMBERS[@]}"; do
  if [ "${MAX_PRS}" -ne 0 ] && [ "${collected}" -ge "${MAX_PRS}" ]; then
    log "Reached MAX_PRS=${MAX_PRS} limit, remaining PRs won't be included in the changelog."
    break
  fi
  body="$(gh api "repos/${UPSTREAM_REPO}/pulls/${num}" --jq '.body // ""' 2>/dev/null)" || {
    log "Failed to fetch PR #${num}, skipping."
    continue
  }
  while IFS= read -r cl; do
    [ -n "$cl" ] && CHANGELOG_LINES+=("$cl")
  done < <(printf '%s\n' "$body" | extract_changelog)
  collected=$((collected + 1))
done

log "Collected changelog lines: ${#CHANGELOG_LINES[@]}"

# --- Build the PR body ----------------------------------------------------

BODY_FILE="$(mktemp)"
trap 'rm -f "$BODY_FILE"' EXIT

{
  echo "This PR merges upstream \`${UPSTREAM_REPO}@${UPSTREAM_BRANCH}\` into \`${TARGET_BRANCH}\`."
  echo "Resolve any conflicts manually and make sure all changes are applied correctly."
  echo
  echo "New upstream PRs: **${#PR_NUMBERS[@]}**."
  echo

  if [ "${#PR_NUMBERS[@]}" -gt 0 ]; then
    echo "<details><summary>Included upstream PRs</summary>"
    echo
    for num in "${PR_NUMBERS[@]}"; do
      # www. instead of https:// so GitHub doesn't turn links into upstream cross-references.
      echo "- www.github.com/${UPSTREAM_REPO}/pull/${num}"
    done
    echo
    echo "</details>"
    echo
  fi

  if [ "${#CHANGELOG_LINES[@]}" -gt 0 ]; then
    echo ":cl: ${CHANGELOG_AUTHOR}"
    printf '%s\n' "${CHANGELOG_LINES[@]}"
    echo "/:cl:"
  fi
} > "$BODY_FILE"

# Guard against GitHub's PR body size limit (~65536 characters).
if [ "$(wc -c < "$BODY_FILE")" -gt 60000 ]; then
  log "PR body too large, trimming the changelog."
  {
    echo "This PR merges upstream \`${UPSTREAM_REPO}@${UPSTREAM_BRANCH}\` into \`${TARGET_BRANCH}\`."
    echo "Resolve any conflicts manually."
    echo
    echo "New upstream PRs: **${#PR_NUMBERS[@]}** (changelog omitted — too large)."
  } > "$BODY_FILE"
fi

readonly PR_TITLE="[IDB IGNORE][MDB IGNORE] Merge Upstream ${UPSTREAM_REPO} ($(date +%d.%m.%Y))"

# --- Create/update the PR -------------------------------------------------

existing="$(gh pr list --repo "${TARGET_REPO}" --state open \
  --base "${TARGET_BRANCH}" --head "${MERGE_BRANCH}" \
  --json number --jq '.[0].number // ""' 2>/dev/null || echo "")"

if [ -n "${existing}" ]; then
  log "PR #${existing} is already open — updating its body."
  gh pr edit "${existing}" --repo "${TARGET_REPO}" --body-file "${BODY_FILE}" \
    || die "failed to update PR #${existing}"
  log "Done: https://github.com/${TARGET_REPO}/pull/${existing}"
else
  log "Creating PR ${MERGE_BRANCH} -> ${TARGET_BRANCH}"
  gh pr create --repo "${TARGET_REPO}" \
    --base "${TARGET_BRANCH}" --head "${MERGE_BRANCH}" \
    --title "${PR_TITLE}" --body-file "${BODY_FILE}" \
    || die "failed to create PR"
fi
