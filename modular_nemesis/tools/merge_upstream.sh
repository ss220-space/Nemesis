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

set -u # ошибка при использовании неинициализированной переменной
set -o pipefail

readonly TARGET_REPO="${TARGET_REPO:-${GITHUB_REPOSITORY:-ss220-space/Nemesis}}"
readonly TARGET_BRANCH="${TARGET_BRANCH:-master}"
readonly UPSTREAM_REPO="${UPSTREAM_REPO:-tgstation/tgstation}"
readonly UPSTREAM_BRANCH="${UPSTREAM_BRANCH:-master}"
readonly MERGE_BRANCH="${MERGE_BRANCH:-merge-upstream}"
readonly CHANGELOG_AUTHOR="${CHANGELOG_AUTHOR:-tgstation}"
readonly MAX_PRS="${MAX_PRS:-400}"

log() { echo "[merge_upstream] $*"; }
die() { echo "[merge_upstream] ОШИБКА: $*" >&2; exit 1; }

# --- Проверки окружения ---------------------------------------------------

[ -d .git ] || die "запускать нужно из корня git-репозитория"
type git >/dev/null 2>&1 || die "требуется git"
type gh  >/dev/null 2>&1 || die "требуется gh (GitHub CLI)"
type jq  >/dev/null 2>&1 || die "требуется jq"

# --- Настройка remote'ов --------------------------------------------------

if ! git remote | grep -qx upstream; then
  log "Добавляю remote upstream -> https://github.com/${UPSTREAM_REPO}.git"
  git remote add upstream "https://github.com/${UPSTREAM_REPO}.git"
else
  git remote set-url upstream "https://github.com/${UPSTREAM_REPO}.git"
fi

log "Получаю апстрим (${UPSTREAM_REPO}@${UPSTREAM_BRANCH})..."
git fetch --no-tags upstream "${UPSTREAM_BRANCH}" || die "не удалось fetch upstream"
git fetch --no-tags origin || die "не удалось fetch origin"

# --- Пересоздание ветки merge-upstream ------------------------------------

if git ls-remote --exit-code --heads origin "${MERGE_BRANCH}" >/dev/null 2>&1; then
  log "Ветка ${MERGE_BRANCH} существует, сбрасываю её на upstream/${UPSTREAM_BRANCH}"
  git checkout -B "${MERGE_BRANCH}" "upstream/${UPSTREAM_BRANCH}"
  git push --force origin "${MERGE_BRANCH}"
else
  log "Создаю ветку ${MERGE_BRANCH} из upstream/${UPSTREAM_BRANCH}"
  git checkout -B "${MERGE_BRANCH}" "upstream/${UPSTREAM_BRANCH}"
  git push -u origin "${MERGE_BRANCH}"
fi

# --- Поиск новых коммитов и номеров PR ------------------------------------

log "Ищу коммиты upstream, которых нет в ${TARGET_BRANCH}..."
# Хронологический порядок (старые -> новые), чтобы changelog шёл по порядку мержа.
mapfile -t COMMIT_LOG < <(git log --reverse --pretty=format:'%s' \
  "origin/${TARGET_BRANCH}..${MERGE_BRANCH}")

if [ "${#COMMIT_LOG[@]}" -eq 0 ]; then
  log "Новых коммитов нет — Nemesis уже синхронизирован с ${UPSTREAM_REPO}. Выходим."
  exit 0
fi

# Собираем уникальные номера PR из сабжей коммитов вида "Title (#12345)".
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

log "Найдено новых PR апстрима: ${#PR_NUMBERS[@]}"

# --- Сбор changelog из тел PR ---------------------------------------------

# Извлекает строки changelog (key: description) из :cl: блока тела PR.
# Переиспользует тот же формат тегов, что и tools/pull_request_hooks/changelogConfig.js.
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
    log "Достигнут лимит MAX_PRS=${MAX_PRS}, остальные PR в changelog не попадут."
    break
  fi
  body="$(gh api "repos/${UPSTREAM_REPO}/pulls/${num}" --jq '.body // ""' 2>/dev/null)" || {
    log "Не удалось получить PR #${num}, пропускаю."
    continue
  }
  while IFS= read -r cl; do
    [ -n "$cl" ] && CHANGELOG_LINES+=("$cl")
  done < <(printf '%s\n' "$body" | extract_changelog)
  collected=$((collected + 1))
done

log "Собрано строк changelog: ${#CHANGELOG_LINES[@]}"

# --- Формирование тела PR -------------------------------------------------

BODY_FILE="$(mktemp)"
trap 'rm -f "$BODY_FILE"' EXIT

{
  echo "Этот PR подтягивает upstream \`${UPSTREAM_REPO}@${UPSTREAM_BRANCH}\` в \`${TARGET_BRANCH}\`."
  echo "Разрешите возможные конфликты вручную и убедитесь, что все изменения применились корректно."
  echo
  echo "Новых PR апстрима: **${#PR_NUMBERS[@]}**."
  echo

  if [ "${#PR_NUMBERS[@]}" -gt 0 ]; then
    echo "<details><summary>Включённые PR апстрима</summary>"
    echo
    for num in "${PR_NUMBERS[@]}"; do
      # www. вместо https:// — чтобы GitHub не превращал ссылки в кросс-реф апстрима.
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

# Защита от лимита тела PR в GitHub (~65536 символов).
if [ "$(wc -c < "$BODY_FILE")" -gt 60000 ]; then
  log "Тело PR слишком большое, обрезаю changelog."
  {
    echo "Этот PR подтягивает upstream \`${UPSTREAM_REPO}@${UPSTREAM_BRANCH}\` в \`${TARGET_BRANCH}\`."
    echo "Разрешите возможные конфликты вручную."
    echo
    echo "Новых PR апстрима: **${#PR_NUMBERS[@]}** (changelog опущен — слишком большой объём)."
  } > "$BODY_FILE"
fi

readonly PR_TITLE="Merge Upstream ${UPSTREAM_REPO} ($(date +%d.%m.%Y))"

# --- Создание/обновление PR -----------------------------------------------

existing="$(gh pr list --repo "${TARGET_REPO}" --state open \
  --base "${TARGET_BRANCH}" --head "${MERGE_BRANCH}" \
  --json number --jq '.[0].number // ""' 2>/dev/null || echo "")"

if [ -n "${existing}" ]; then
  log "PR #${existing} уже открыт — обновляю его тело."
  gh pr edit "${existing}" --repo "${TARGET_REPO}" --body-file "${BODY_FILE}" \
    || die "не удалось обновить PR #${existing}"
  log "Готово: https://github.com/${TARGET_REPO}/pull/${existing}"
else
  log "Создаю PR ${MERGE_BRANCH} -> ${TARGET_BRANCH}"
  gh pr create --repo "${TARGET_REPO}" \
    --base "${TARGET_BRANCH}" --head "${MERGE_BRANCH}" \
    --title "${PR_TITLE}" --body-file "${BODY_FILE}" \
    || die "не удалось создать PR"
fi
