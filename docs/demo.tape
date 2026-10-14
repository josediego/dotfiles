# VHS script — records the onboarding (Fresh setup) flow in --dry-run.
# Regenerate with:  vhs docs/demo.tape
Output docs/demo.gif

Set Shell "bash"
Set FontSize 16
Set Width 1000
Set Height 480
Set Padding 20
Set Theme "nord"
Set CursorBlink false
Set TypingSpeed 55ms

# Setup (hidden): clean prompt, brew on PATH, enter the repo, clear.
Hide
Type `export PS1="$ "`
Enter
Type `eval "$(/opt/homebrew/bin/brew shellenv)" && cd ~/workspace/dotfiles && clear`
Enter
Sleep 800ms
Show

Type "./tui.sh --dry-run"
Enter
Sleep 3800ms
Screenshot docs/01-menu.png

# Main menu → "Fresh setup"
Enter
Sleep 1800ms
Screenshot docs/02-context.png

# Context → "personal"
Enter
Sleep 1800ms
Screenshot docs/03-profiles.png

# Profiles (multi-select): pick aesthetics + languages, then confirm
Space
Sleep 450ms
Down
Space
Sleep 900ms
Enter
Sleep 2800ms
Screenshot docs/04-dryrun.png
Sleep 1800ms
