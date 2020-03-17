# wg-git

A cute way to manage wireguard configs and keys with git~


### Installation

Clone this repo or download a tarball.

``rm -rf .git; git init``


### 30,000ft quickstart

- Add your configs to ``confs/`` (empty files is fine to start)
- commit them
- run ``./gen-wg0.sh $host``
- commit ``keys/``
- push to hosts, run ``./gen-wg0.sh $host``


### Preamble 

Right now the project is very limited, mostly because I made it more opinionated
than it ought to have been.

It was based on this introductory blog post by stavros:
https://www.stavros.io/posts/how-to-configure-wireguard/

The idea is you have configs and public keys checked into this repo, with
private keys stored excusively on the host they were generated.

Right now there's only ``me.private``. There's even a lockfile, ``me`` ,to stop
the utility for generating keys across hosts. 

I realise now that's limited. So that'll get addressed if there's interest.

> (Then again if it's a different interface you could just clone the repo into
a different directory? idk I haven't actually used wg yet because my hobby
kvm server's kernel is outdated, and my home network is down, and the wifi
driver on this thinkpad crashed and I wanted to finish before having to reboot
so I can get back to tptacek then sleep)


### Usage

Make your wg config in ``confs/$host.conf``.
Where ``$host`` is a suitable name for your computer, ``[A-Za-z0-9_-]``

It's a standard wireguard config, but you get the following functions:

``$public(host)`` Replaced with the public key of ``host``.

``$private(host)`` Replaced with the private key of ``host``.
> ``$private()`` only works for your ``host``, cause there's only one private key per repo rn.


``confs/thinkpad.conf``

```ini
[Interface]
Address = 10.8.2.6
ListenPort = 10826
PrivateKey = $private(thinkpad)

[Peer]
PublicKey = $public(kvm)
Endpoint = 133.73.133.78:10821
AllowedIPs = 10.8.2.0/24

# PersistentKeepalive = 25
```

Generate a keypair and compile the config:

```sh
$ touch conf
$ chmod 600 conf # owner-only read-write

$ ./gen-wg0.sh thinkpad > conf
Initialised ./me.
Initialised me.private and keys/thinkpad.public.
Linked me.public -> keys.thinkpad.public.
OK.

$ sudo chown root:root conf
$ sudo mv conf /etc/wireguard/wg0.conf # install

$ wg-quick up wg0 # bring it online
```


TODO: maybe write to ``/etc/wireguard`` directly.

You can also just:

```sh
./gen-wg0.sh thinkpad | sudo tee /etc/wireguard/wg0.conf >/dev/null
wg-quick up wg0
```


### Overview

This is the layout of the files:

Before:

```sh
wg/
├── confs/
│   ├── kvm.conf
│   └── thinkpad.conf
├── keys/
│   └── kvm.public "mZu3P02..YwUusmprTE="
├── .git/
├── .gitignore "me*"
└── gen-wg0.sh
```

After ``./gen-wg0.sh thinkpad``:

```sh
wg/
├── confs/
│   ├── kvm.conf
│   └── thinkpad.conf
├── keys/
│   ├── kvm.public "mZu3P02..YwUusmprTE="
│   └── thinkpad.public "UYfMay4YQtj+..AjL9FL8w8="
├── .git/
├── .gitignore "me*"
├── gen-wg0.sh
├── me "thinkpad"
├── me.private "cMP4BcyXJ..sdW4n0rkafXqrdX4="
└── me.public -> keys/thinkpad.public
```

Then you can ``git add -A; git commit -m "add thinkpad key"``.

Only ``keys/thinkpad.public`` should be added,
``me``, ``me.private`` and ``me.public`` are all .gitignore'd.

The intent is to not commit and not distribute ``me*`` files.



### Roadmap

See if there are more useful functions to implement.

> (~10% of the file is implementing the functions, the rest is sanity checks and
enforcing the weird opinionated ``me*`` I've got going on.)

Perhaps some kind of ``$public_ip(host)``? It'd involve a lookup table and all
that good stuff.

I dunno. Maybe I'm the only one who is terrified of seeing private keys pooped
out on my tty and this is a non-issue.

