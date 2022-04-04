parse_git_branch() {
     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}
export PS1="\u@\h \[\033[32m\]\w\[\033[33m\]\$(parse_git_branch)\[\033[00m\] $ "

# https://bashrcgenerator.com/
export PS1="\T:\[$(tput sgr0)\]\[\033[38;5;11m\]\h\[$(tput sgr0)\]:\W:\[$(tput sgr0)\]\[\033[38;5;14m\]\$(git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/')\[$(tput sgr0)\]\\$\[$(tput sgr0)\]"
