# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
  export ZSH=/home/klim/.oh-my-zsh

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="terminalparty"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
setopt EXTENDED_GLOB
unsetopt CASE_GLOB

export EDITOR=vim

extract () {
    if [ -f $1 ] ; then
    case $1 in
    *.tar.bz2)   tar xjf $1        ;;
    *.tar.gz)    tar xzf $1     ;;
    *tar.xz)     tar xvfJ $1    ;;
    *.bz2)       bunzip2 $1       ;;
    *.rar)       unrar x $1     ;;
    *.gz)        gunzip $1     ;;
    *.tar)       tar xf $1        ;;
    *.tbz2)      tar xjf $1      ;;
    *.tbz)       tar -xjvf $1    ;;
    *.tgz)       tar xzf $1       ;;
    *.zip)       unzip $1     ;;
    *.Z)         uncompress $1  ;;
    *.7z)        7z x $1    ;;
    *)           echo "I don't know how to extract '$1'..." ;;
    esac
 else
 echo "'$1' is not a valid file"
 fi
}

alias -g xcopy='xclip -selection clipboard'
alias -g xpaste='xclip -selection clipboard -o'
alias -s txt=vim
alias -s jpg=feh
alias -s png=feh
alias -g bat='acpi'
alias -g net='iw dev wlp2s0 link'
alias -g vol='alsamixer'
alias -g cpu='htop'
alias -g temp='sensors'
alias -g ram='free -h'
alias -g c='clear'
alias -g l='ls -la'
alias -g h='history'
