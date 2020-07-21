#!/bin/bash

# Shared environment variables.

# Use Homebrew binaries.
HOMEBREW_PREFIX=$(brew --prefix)
HOMEBREW_BIN=$HOMEBREW_PREFIX/bin
GIT=$HOMEBREW_BIN/git
GPG=$HOMEBREW_BIN/gpg
GPG_AGENT=$HOMEBREW_BIN/gpg-agent
GPGCONF=$HOMEBREW_BIN/gpgconf
YKMAN=$HOMEBREW_BIN/ykman
BOLD=$(tput bold)
RED=$(tput setaf 1)
RESET=$(tput sgr0) # Reset text

SSH_ENV="$HOME/.ssh/environment"

# Folders and files.
DEFAULT_GPG_HOMEDIR=$HOME/.gnupg
DEFAULT_GPG_AGENT_CONF=$DEFAULT_GPG_HOMEDIR/gpg-agent.conf

# Functions.

# Backup GPG agent configuration in default GPG homedir, if it exists.
function backup_default_gpg_agent_conf {
    if [[ -e $DEFAULT_GPG_AGENT_CONF ]]
    then
        DEFAULT_GPG_AGENT_CONF_BACKUP=$DEFAULT_GPG_AGENT_CONF.$(date +%s)
        if [[ -e $DEFAULT_GPG_AGENT_CONF_BACKUP ]]
        then
            echo "Unlikely for $DEFAULT_GPG_AGENT_CONF_BACKUP to exist!"
            exit 4
        else
            echo "Backing up $DEFAULT_GPG_AGENT_CONF to $DEFAULT_GPG_AGENT_CONF_BACKUP"
            mv $DEFAULT_GPG_AGENT_CONF $DEFAULT_GPG_AGENT_CONF_BACKUP
        fi
    else
        echo "$DEFAULT_GPG_AGENT_CONF doesn't exist"
    fi
}

# Get the GPG keyid using the given homedir.
function get_keyid {
    echo $($GPG --homedir=$1 --card-status | grep 'Signature key' | cut -f2 -d: | tr -d ' ')
}

function vercomp {
    if [[ $1 == $2 ]]
    then
        return 0
    fi
    local IFS=.
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
