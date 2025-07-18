# Use `hub` as our git wrapper:
#   http://defunkt.github.com/hub/
hub_path=$(which hub)
if (( $+commands[hub] ))
then
  alias git=$hub_path
fi

# The rest of my fun git aliases
alias gl='git pull --prune'
alias glog="git log --graph --pretty=format:'%Cred%h%Creset %an: %s - %Creset %C(yellow)%d%Creset %Cgreen(%cr)%Creset' --abbrev-commit --date=relative"
alias gpuoh='git push -u origin HEAD'
alias gp='git pull'

# Remove `+` and `-` from start of diff lines; just rely upon color.
alias gd='git diff --color | sed "s/^\([^-+ ]*\)[-+ ]/\\1/" | less -r'

alias gcm='git checkout main'
alias gcp='git checkout -'
alias gc='git commit'
alias gca='git commit -a'
alias gco='git checkout'
alias gcob='git checkout -b'
alias gcb='git copy-branch-name'
alias gb='git branch'
alias gs='git status'
alias gac='git add -A && git commit -m'
alias ge='git-edit-new'

# git prune branches
alias gpb='git fetch --prune && git branch -r | awk "{print \$1}" | egrep -v -f /dev/fd/0 <(git branch -vv | grep origin) | awk "{print \$1}" | xargs git branch -D'
