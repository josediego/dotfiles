# VHS script — records the onboarding (Fresh setup) flow in --dry-run.
# Regenerate with:  vhs docs/demo.tape
Output docs/demo.gif

Set Shell "bash"
Set FontFamily "Commit Mono"
Set FontSize 20
Set Width 1120
Set Height 720
Set Padding 28
Set Theme "nord"

# Setup (hidden): put brew on PATH, enter the repo, clear the screen.
Hide
Type `eval "$(/opt/homebrew/bin/brew shellenv)" && cd ~/workspace/dotfiles && clear`
Enter
Sleep 1s
Show

Type "./tui.sh --dry-run"
Enter
Sleep 3500ms
Screenshot docs/01-menu.png

# Main menu → "Fresh setup"
Enter
Sleep 2500ms
Screenshot docs/02-context.png

# Context → "personal"
Enter
Sleep 2500ms
Screenshot docs/03-profiles.png

# Profiles (multi-select): pick aesthetics + languages, then confirm
Space
Sleep 500ms
Down
Space
Sleep 1s
Enter
Sleep 3s
Screenshot docs/04-dryrun.png
Sleep 2s
