#!/bin/sh


# exit if status != 0
set -e
set -o pipefail

# error & exit
err() { echo "ERROR: $@" >&2; exit 1; }

# just to distinguish from file IO
#   maybe we'll add colours someday
log() { echo "$@"; }

NL=$'\n' # newline



## SETUP & SANITY

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
    err "No config for $me."
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
    log "Initialised ./me."
fi


# set $pubkey variable if we can by reading me.private
unset pubkey # in case of environment inheritance
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
        log "Created missing softlink me.public -> keys/$me.public."
        
    else
        
        # if we've got the private key, just regenerate the pubkey
        #   this is automagic and that's fine
        if [ -n "$pubkey" ]; then
            echo "$pubkey" > "keys/$me.public"
            log "Regenerated keys/$me.public."
            ln -s "keys/me.public" me.public # might fail, they can re-run
            log "Linked me.public -> keys/$me.public."
        fi
        
    fi
    
fi


# OK this is a good state:
#   if both me.private and me.public exist;
#       then me.public is a softlink to keys/$me.public
#       and is indeed the corresponding public key
#   if neither exist; that's chill we'll make both
#   if me.public was missing we made it again

# the last case is we don't have either!
#   so let's make both~
if [ -z "$pubkey" ]; then
    wg genkey | tee me.private | wg pubkey > "keys/$me.public"
    ln -s "keys/me.public" me.public
    pubkey="$(cat me.public)"
    log "Initialised me.private and me.public."
fi



## BUSINESS




