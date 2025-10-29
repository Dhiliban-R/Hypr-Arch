#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

eval "$(starship init bash)"
export PATH="$HOME/.npm-global/bin:$PATH"
export PATH="/usr/bin:$PATH"
export PATH="/usr/bin:$PATH"
