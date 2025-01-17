#!/usr/bin/env bash

function which_flavour {
    if [[ -f /etc/os-release ]]; then
        detected="$(grep '^ID=' /etc/os-release | cut -d= -f2)"
    fi
    echo "$detected"
}

case "$OSTYPE" in
    darwin*)
        OS='macos'
        ;;
    linux*)
        OS=$(which_flavour)
        ;;
    *)
        OS="not detected"
        ;;
esac

echo "OS detected is $OS"
read -rp "Is it correct ? (y|N)" input
input=$(echo "$input" | tr "[:lower:]" "[:upper:]")
case $input in yes|YES|y|Y|Yes)
        ;;
    *)
        echo "Your OS is not supported"
        exit 1
esac

case ${OS} in macos)
        PKG_MANAGER="brew"
        PKG_MANAGER_ENV=""
        PKG_MANAGER_INSTALL="install"
        PKG_MANAGER_UPDATE="update"
        PKG_MANAGER_UPGRADE="upgrade"
        PKG_CHECK="brew"
        PKG_CHECK_ARGS="list"
        HOMEBREW_PREFIX=$(brew --prefix)
        HOMEBREW_BIN=$HOMEBREW_PREFIX/bin
        GIT=$HOMEBREW_BIN/git
        GPG=$HOMEBREW_BIN/gpg
        GPG_AGENT=$HOMEBREW_BIN/gpg-agent
        GPGCONF=$HOMEBREW_BIN/gpgconf
        YKMAN=$HOMEBREW_BIN/ykman
        CLIP="pbcopy"
        CLIP_ARGS=""
        PINENTRY="/usr/local/bin/pinentry-tty"
        OPEN="open"
        DEPS=(
            "expect"
            "git"
            "gpg"
            "pinentry-mac"
            "ykman"
        )
        export HOMEBREW_NO_AUTO_UPDATE=1
        ;;
    ubuntu|debian)
        PKG_MANAGER="apt"
        PKG_MANAGER_ENV="sudo"
        PKG_MANAGER_INSTALL="install"
        PKG_MANAGER_UPDATE="update"
        PKG_MANAGER_UPGRADE="install"
        PKG_CHECK="apt"
        PKG_CHECK_ARGS="show"
        BIN_PATH="/usr/bin"
        GIT="${BIN_PATH}/git"
        GPG="${BIN_PATH}/gpg"
        GPG_AGENT="${BIN_PATH}/gpg-agent"
        GPGCONF="${BIN_PATH}/gpgconf"
        YKMAN="${BIN_PATH}/ykman"
        CLIP="${BIN_PATH}/xclip"
        CLIP_ARGS="-selection clipboard -i"
        PINENTRY="/usr/bin/pinentry-tty"
        OPEN="xdg-open"
        DEPS=(
            "expect"
            "git"
            "gpg"
            "pinentry-tty"
            "python"
            "scdaemon"
            "yubikey-manager"
            "xclip"
        )
        sudo apt-add-repository ppa:yubico/stable
        ;;
    arch)
        PKG_MANAGER="pacman"
        PKG_MANAGER_ENV="sudo"
        PKG_MANAGER_INSTALL="-S"
        PKG_MANAGER_UPDATE="-Sy"
        PKG_MANAGER_UPGRADE="-S"
        PKG_CHECK="pacman"
        PKG_CHECK_ARGS="-Qi"
        BIN_PATH="/usr/bin"
        GIT="${BIN_PATH}/git"
        GPG="${BIN_PATH}/gpg"
        GPG_AGENT="${BIN_PATH}/gpg-agent"
        GPGCONF="${BIN_PATH}/gpgconf"
        YKMAN="${BIN_PATH}/ykman"
        CLIP="${BIN_PATH}/xclip"
        CLIP_ARGS="-selection clipboard -i"
        PINENTRY="/usr/bin/pinentry"
        OPEN="xdg-open"
        # shellcheck disable=SC2034
        DEPS=(
            "expect"
            "gnupg"
            "pinentry"
            "git"
            "yubikey-manager"
            "xclip"
            "pcsclite"
        )
        ;;
    *)
        echo "Sorry, your OS is not supported"
        exit 1
esac

# Use Homebrew binaries.
export PKG_MANAGER
export PKG_MANAGER_ENV
export PKG_MANAGER_INSTALL
export PKG_MANAGER_UPDATE
export PKG_MANAGER_UPGRADE
export PKG_CHECK
export PKG_CHECK_ARGS
export GIT
export GPG
export GPG_AGENT
export GPGCONF
export YKMAN
export CLIP
export CLIP_ARGS
export OPEN
export PINENTRY

# Colors galore.
BOLD=$(tput bold)
export BOLD
RED=$(tput setaf 1)
export RED
RESET=$(tput sgr0) # Reset text
export RESET

# SSH.
export SSH_ENV="$HOME/.ssh/environment"

# Folders and files.
export DEFAULT_GPG_HOMEDIR=$HOME/.gnupg
export DEFAULT_GPG_AGENT_CONF=$DEFAULT_GPG_HOMEDIR/gpg-agent.conf
export DEFAULT_GPG_CONF=$DEFAULT_GPG_HOMEDIR/gpg.conf

# Functions.

# Backup configuration in default GPG homedir, if it exists.
function backup_conf {
    local conf
    local conf_backup
    conf="$1"

    if [[ -e "$conf" ]]
    then
        conf_backup=$conf.$(date +%s)
        if [[ -e $conf_backup ]]
        then
            echo "Unlikely for $conf_backup to exist!"
            exit 4
        else
            echo "Backing up $conf to $conf_backup"
            mv "$conf" "$conf_backup"
        fi
    else
        echo "$conf doesn't exist"
    fi
}

# Get the GPG keyid using the given homedir.
function get_keyid {
    $GPG --homedir="$1" --card-status | grep 'Signature key' | cut -f2 -d: | tr -d ' '
}

function vercomp {
    if [[ $1 == "$2" ]]
    then
        return 0
    fi
    local IFS=.
    # shellcheck disable=SC2206
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            return 2
        fi
    done
    return 0
}

function join { local IFS="$1"; shift; echo "$*"; }
