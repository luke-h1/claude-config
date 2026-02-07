# claude-config

My [Claude Code](https://docs.anthropic.com/en/docs/claude-code) configuration - settings and skills.

## Quick start

```bash
git clone https://github.com/brianlovin/claude-config.git
cd claude-config
./install.sh
```

## What's included

### Settings

- `settings.json` - Global permissions and preferences
- `statusline.sh` - Custom statusline showing token usage

### Skills

Reusable capabilities that Claude can invoke (use `/skill-name` in Claude):

| Skill      | Description                                         |
| ---------- | --------------------------------------------------- |
| `rams`     | Run accessibility and visual design review          |
| `reclaude` | Refactor CLAUDE.md files for progressive disclosure |
| `simplify` | Code simplification specialist                      |
| `deslop`   | Remove AI-generated code slop                       |

## Managing your config

```bash
# See what's synced vs local-only
./sync.sh

# Preview what install would do
./install.sh --dry-run

# Add a local skill to the repo
./sync.sh add skill my-skill
./sync.sh push

# Pull changes on another machine
./sync.sh pull

# Remove a skill from repo (keeps local copy)
./sync.sh remove skill my-skill
./sync.sh push
```

### Safe operations with backups

All destructive operations create timestamped backups:

```bash
# List available backups
./sync.sh backups

# Restore from last backup
./sync.sh undo
```

### Validate skills

```bash
./sync.sh validate
```

## Local-only config

Not everything needs to be synced. The install script only creates symlinks for what's in this repo - it won't delete your local-only skills.

Machine-specific permissions accumulate in `~/.claude/settings.local.json` (auto-created by Claude, not synced).

## Creating your own

Fork this repo and customize! The structure is simple:

```
claude-config/
├── settings.json      # Claude Code settings
├── statusline.sh      # Optional statusline script
├── skills/            # Skills (subdirectories with SKILL.md)
├── agents/            # Subagent definitions
├── rules/             # Rule files
└── tests/             # Bats tests
```

## See also

- [Claude Code docs](https://docs.anthropic.com/en/docs/claude-code)

## Inspirations

- [Brian Lovin's claude config](https://github.com/brianlovin/claude-config)
