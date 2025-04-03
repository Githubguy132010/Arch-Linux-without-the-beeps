# ~/.bashrc: executed by bash for non-login shells

# Disable terminal bell in bash
bind 'set bell-style none'

# If not running interactively, don't do anything else
[[ $- != *i* ]] && return

# Color prompt
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# Enable color support
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Add useful aliases
alias ll='ls -l'
alias la='ls -la'

# History settings
HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=2000