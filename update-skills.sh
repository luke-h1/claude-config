#!/bin/bash
set -e

CONFIG_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_MANIFEST="$CONFIG_DIR/skills.json"
DRY_RUN=false
SKILL_FILTER=""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
BOLD='\033[1m'
RESET='\033[0m'

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -s|--skill)
            SKILL_FILTER="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: ./update-skills.sh [options]"
            echo ""
            echo "Fetches latest versions of remote skills from their upstream repos"
            echo "and updates the local copies in the config repo."
            echo ""
            echo "Options:"
            echo "  -n, --dry-run         Show what would be updated without making changes"
            echo "  -s, --skill <name>    Update only the specified skill"
            echo "  -h, --help            Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [ ! -f "$SKILLS_MANIFEST" ]; then
    echo -e "${RED}Error:${RESET} skills.json not found at $SKILLS_MANIFEST"
    exit 1
fi

if ! command -v npx &>/dev/null; then
    echo -e "${RED}Error:${RESET} npx is required but not found"
    exit 1
fi

# Use python3 to group skills by repo and output as lines of "repo:skill1 skill2 ..."
grouped=$(python3 -c "
import json, sys
data = json.load(open('$SKILLS_MANIFEST'))
skill_filter = '$SKILL_FILTER'
groups = {}
for s in data.get('remote_skills', []):
    if skill_filter and s['name'] != skill_filter:
        continue
    repo = s['repo']
    groups.setdefault(repo, []).append(s['skill'])
if not groups:
    sys.exit(1)
for repo, skills in groups.items():
    print(repo + ':' + ' '.join(skills))
") || {
    if [ -n "$SKILL_FILTER" ]; then
        echo -e "${RED}Error:${RESET} Skill '$SKILL_FILTER' not found in skills.json"
    else
        echo "No remote skills configured."
    fi
    exit 1
}

echo -e "${BOLD}Updating Remote Skills${RESET}"
echo "======================"
echo ""

updated=0
failed=0
skipped=0

echo "$grouped" | while IFS=: read -r repo skills; do
    echo -e "${BLUE}Fetching from${RESET} $repo..."

    if $DRY_RUN; then
        echo -e "  ${BLUE}[dry-run]${RESET} Would fetch skills: $skills"
        continue
    fi

    # Re-install from upstream to refresh ~/.agents/skills/
    if npx -y skills add "$repo" --skill $skills -y 2>&1 | while read -r line; do
        printf "."
    done; then
        echo ""

        # Copy updated skills from the universal location into repo
        for skill_name in $skills; do
            src="$HOME/.agents/skills/$skill_name"
            dest="$CONFIG_DIR/skills/$skill_name"

            if [ ! -d "$src" ]; then
                echo -e "  ${RED}✗${RESET} $skill_name (not found after fetch)"
                ((failed++)) || true
                continue
            fi

            # Check if content actually changed
            if [ -d "$dest" ] && diff -rq "$src" "$dest" &>/dev/null; then
                echo -e "  ${RESET}○${RESET} $skill_name (up to date)"
                ((skipped++)) || true
            else
                rm -rf "$dest"
                cp -r "$src" "$dest"
                echo -e "  ${GREEN}✓${RESET} $skill_name (updated)"
                ((updated++)) || true
            fi
        done
    else
        echo ""
        echo -e "  ${RED}✗${RESET} Failed to fetch from $repo"
        for skill_name in $skills; do
            ((failed++)) || true
        done
    fi
done

echo ""
echo -e "${BOLD}Done.${RESET} Run './sync.sh push' to commit any updates."
