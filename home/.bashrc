# Omarchy environment (OMARCHY_PATH + PATH), needed even for non-interactive shells
[[ -r /usr/share/omarchy/default/bash/env-bootstrap ]] && source /usr/share/omarchy/default/bash/env-bootstrap

# If not running interactively, don't do anything else (leave this above the rc source)
[[ $- != *i* ]] && return

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source "$OMARCHY_PATH/default/bash/rc"

# Add your own exports, aliases, and functions here.
# Use the systemd-managed SSH agent
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
# Make an alias for invoking commands you use constantly
# alias p='python'

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/home/nikhil/google-cloud-sdk/path.bash.inc' ]; then . '/home/nikhil/google-cloud-sdk/path.bash.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/home/nikhil/google-cloud-sdk/completion.bash.inc' ]; then . '/home/nikhil/google-cloud-sdk/completion.bash.inc'; fi
