#!/bin/sh

# exit if status != 0
set -e
set -o pipefail

# error & exit
err() { echo "ERROR: $@" >&2; exit 1; }

NL=$'\n' # newline


# who am I
me="$1"
ALLOWED_CHARS='[A-z0-9_\-]' # characters allowed in the host name

if [ -z "$me" ]; then err "Please specify a host."; fi

if [ -n "$(echo "$me" | tr -d "$ALLOWED_CHARS")" ]; then
    err "Only $ALLOWED_CHARS can be in the host."
fi


# don't bother with unconfigured hosts
c="confs/$me.conf"

if [ ! -e "$c" ]; then
    echo "No config for $me." >&2
    exit 1
fi



# check that all the state matches

# ./me is a small safeguard
if [ -e me ] && [ "$me" != "$(cat me)" ]; then
    err "./me exists and doesn't match $me." \
        "${NL}Please delete the me* files if you are changing the name" \
        "or configuring a different host." \
        "${NL}These files should $(tput bold;tput smul)not$(tput sgr0) be" \
        "moved around."
fi

if [ ! -e me ]; then
    echo "$me" > me
    echo "Initialised ./me."
fi

# set $pubkey variable if we can by reading me.private
if [ -e me.private ]; then
    pubkey="$(wg pubkey < me.private)"
fi

# don't generate a private key until we figure out the pubkey situation
if [ -e me.public ]; then
    
    ln="$(readlink me.public)"
    if [ "$ln" != "keys/$me.public" ]; then
        err "me.public exists, but isn't a softlink to keys/$me.public."
    fi
    
    # $pubkey was generated from me.private (if it exists)
    #   read this if as `if me.private exists and is a valid private key`
    #   (-z means "empty string" for y'all shell noobs, -n means non-empty)
    if [ -z "$pubkey" ]; then
        err "me.public exists, but we don't have the private key." \
            "${NL}Probably delete me.public."
    fi
    
    if [ "$(cat me.public)" != "$pubkey" ]; then
        err "me.public exists, but it isn't the public key of me.private."
    fi
    
else
    
    # OK but what if our pubkey exists, it's just stranded in keys/?
    #   this is kinda automagic, and that's fine.
    if [ -e "keys/$me.public" ]; then
        
        if [ -z "$pubkey" ]; then
            err "keys/$me.public exists, but we don't have the private key." \
                "${NL}Probably delete it."
        fi
        
        if [ "$(cat "keys/$me.public")" != "$pubkey" ]; then
            err "keys/$me.public exists, but it isn't the public key of" \
                "me.private."
        fi
        
        ln -s "keys/$me.public" me.public
        echo "Created missing softlink me.public -> keys/$me.public."
        
    fi
    
fi


# ok this is a good state:
#   if both me.private and me.public exist:
#       me.public is a softlink to keys/$me.public
#       and is indeed the corresponding public key
#   if neither exist; that's chill we'll make both
#   just as long as me.public doesn't exist alone.


#   let's start by making a private key if we need to;
#       then go on to ensure the public key exists too.


if [ ! -e me.private ]; then
    :
fi




