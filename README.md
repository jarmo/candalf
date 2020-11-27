# Candalf

Candalf is a server wizard with a can-do attitude! He can cast spells on your
systems to make them turn into what you want.


## Spells?! Wait, What?!

Now that Candalf has gotten your attention we can talk more seriously.

Candalf is a simple tool that helps to orchestrate Linux and Unix-like system
configuration/setup/management using SSH.

There are many tools that do a similar
job (like [Ansible](https://www.ansible.com/), [Chef](https://www.chef.io/), [Puppet](https://puppet.com/) etc.) however
Candalf sets itself apart from them by being much easier to learn and use since there is no need to learn yet another
specific DSL language.

Candalf uses shell scripts (called spells) to do everything which means that it's really simple, explicit and easy to troubleshoot
manually in case of any problems.


## Features

* Very **easy** to learn and use since the only knowledge required is writing regular `shell` scripts;
* Very **flexible** - everything you can do manually from command line can be also done with Candalf;
* Very easy to install since there are no dependencies except a **shell** and Candalf itself;
* Spells are **cast only once** and cast again only when the spell file itself has been changed;
* It's **blazing fast** since only changed spells are sent to the server using rsync and only one ssh connection is made to cast all of them;
* Any shell is supported since spells are executed using their **shebang** line;
* Very easy to understand what Candalf does exactly since it is implemented as a **few hundred lines** of shell scripts;
* Supports **Ubuntu** (Debian Linux) and **FreeBSD** (Unix-like) OS-es out of the box, but adding support to a new Linux/Unix-like OS is pretty easy too.


## Dependencies

To use Candalf to cast spells to a clean system, the following requirements need to be met:

* System should be running a **supported** OS;
* SSH server should be running at port **22** and it should be accessible from your machine;
* Logging in with **root password** over SSH should be allowed and enabled;
* `rsync` needs to be installed on the current system (it will be installed automatically on the remote system when needed).

When SSH server is running on a non-standard port already and/or password login is
disabled then it is still possible to use Candalf, but some extra steps
are needed. See more in [Installation](#installation) section.


## Installation

First, clone Candalf itself:
```bash
git clone https://github.com/jarmo/candalf.git
```

Create a symlink into some directory in your `$PATH`, for example:
```bash
sudo ln -s $(realpath candalf/candalf.sh) /usr/local/bin/candalf
```

Create a separate project/directory for your server spell scripts:
```bash
mkdir -p example.org/spells
```

Create your first spell scripts:
```bash
cd example.org

cat << 'EOF' > spells/now.sh
#!/usr/bin/env bash

set -Eeuo pipefail
VERBOSE="${VERBOSE:-""}"
if [[ "$VERBOSE" != "" ]]; then set -x; fi

date > ~/now
EOF

cat << 'EOF' > spells/me.sh
#!/usr/bin/env bash

set -Eeuo pipefail
VERBOSE="${VERBOSE:-""}"
if [[ "$VERBOSE" != "" ]]; then set -x; fi

id -un > ~/me
EOF
```

Create a script for casting all the spells:
```bash
cat << 'EOF' > example.org.sh
#!/usr/bin/env bash

set -Eeuo pipefail
VERBOSE="${VERBOSE:-""}"
if [[ "$VERBOSE" != "" ]]; then set -x; fi

. ${CANDALF_ROOT:="."}/lib/cast.sh

cast spell/now.sh 
cast spell/me.sh
EOF
```

PS! File name should be the actual domain name for the server (in this
case it's `example.org`) because Candalf uses that name to connect to the
correct server.

Cast all spells to the server:
```bash
candalf example.org.sh
```

During the first run you will be asked a couple of times the root password of the remote system to
create a SSH key and copy it to the server. After that initial run of Candalf, SSH
server will be running on a random port, password authentication via SSH will
be disabled and a SSH configuration will be created locally into `~/.ssh/config` under the server domain name Host key.

For the example above, there will be an entry in the `~/.ssh/config` like the following:
```bash
Host example.org 
  Hostname example.org
  Port [RANDOM PORT]
  User root
  IdentityFile /home/USER/.ssh/example.org
  IdentitiesOnly yes
  PasswordAuthentication no
  PubkeyAuthentication yes
  PreferredAuthentications publickey
```

There will be also SSH public/private key under `~/.ssh` having the server domain
name as their file names (~/.ssh/example.org and ~/.ssh/example.org.pub respectively).


### Installation With Preconfigured SSH Server

When server does not have password authentication enabled over SSH then it's
easy to start using Candalf too. Just make sure that you have
private/public key under `~/.ssh` having the same name as your server domain name
and create a SSH configuration similar to shown above.
This will make Candalf to assume that SSH authentication with a public key
has been already completed and you can start using it normally.


## Spell Book

A spell book script is required to cast spells to a system. This is basically a script which describes
all the spells that should be cast on a remote system to configure and set it up - think of installing
all necessary dependencies and configuring them as you would do manually.

Good practice would be not to do any changes manually on the remote system, but
only use spell files and keep these in the VCS too for having a better understanding
of the remote system (and for a good disaster recovery/scaling reasons).
You should think of a remote system being a read-only system when it comes to installing new packages or configuring anything there.

Spell book script of a server is pretty simple. Let's create one without any spells in it:
```bash
cat << 'EOF' > example.org.sh
#!/usr/bin/env bash

set -Eeuo pipefail
VERBOSE="${VERBOSE:-""}"
if [[ "$VERBOSE" != "" ]]; then set -x; fi

. ${CANDALF_ROOT:="."}/lib/cast.sh
EOF
```

It's pretty straightforward - first it has a `shebang` line which instructs
Bash to be used as a running shell, then a bunch of important `set` commands (read from
the shell manual or
from [this blog post](https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/) to understand what they're for)
and `lib/cast.sh` is sourced so that a few Candalf helper functions could be used.
One important thing to notice here is that the name of the spell book script
file has to match the domain name of the server you want to cast all the spells.

Now, adding spells to the spell book script is really easy too - just need
to execute function `cast` with a parameter to spell file. Spell files
can be placed anywhere but the argument to `cast` function should have
a relative path from the spell book script to the file.
It's a good practice to put them under directory
called `spells` with separate subdirectories for different dependencies.
For example `spells/nginx` directory could have files called
`nginx.sh` and `firewall.sh` which would install Nginx and configure firewall
to allow traffic to ports 80/443 respectively. Let's add one spell to the
spell book, which updates and upgrades all packages on the remote Debian system:

```bash
mkdir -p spells/system

cat << 'EOF' > spells/system/upgrade.sh
#!/usr/bin/env bash

set -Eeuo pipefail
VERBOSE="${VERBOSE:-""}"
if [[ "$VERBOSE" != "" ]]; then set -x; fi

apt update -y
apt upgrade -y
EOF
```

Again pretty straightforward - standard boiler-place code in the header of the
script and then the important part of running `apt` commands for upgrading the system packages.
It's always a good idea to do this on a new system before doing anything else.

Let's add this spell into our spell book script otherwise it will not be cast:
```bash
echo "cast spells/system/upgrade.sh" >> example.org.sh
```

Let's cast all the defined spells (we assume that Candalf itself has been installed already
as specified in the [Installation](#installation) section):
```bash
candalf example.org.sh
```

If everything goes well then a SSH key is going to be created, it will be
copied to the server, SSH server will be running on a random port and password
authentication via SSH server is disabled. There will be also a lot of output
from apt upgrading the system.

If you run the same command again then not much happens because Candalf has
already cast this spell and will not do much again. However, as soon as you
change that spell script then it will be cast again from the beginning to the
end.


## Casting Spells for Unprivileged Users

Since Candalf connects to the server using `root` user by default then all
spells are casted to that user. However, if you need to cast spells to other
users then this is also possible.

Here's how we would do that:
```bash
mkdir -p spells/john

cat << 'EOF' > spells/john/whoami.sh
#!/usr/bin/env bash

set -Eeuo pipefail
VERBOSE="${VERBOSE:-""}"
if [[ "$VERBOSE" != "" ]]; then set -x; fi

whoami
EOF

echo "cast_as john spells/john/whoami.sh" >> example.org.sh

candalf example.org.sh
```

Notice that instead of using function `cast` we need to use function called
`cast_as` with a user name parameter and a spell path. That's the only
difference between applying spells to the `root` or to the specific user.


## Using Different Shells

It's possible to write spells and spell-book scripts in whatever shell you
prefer - just use appropriate [shebang](https://en.wikipedia.org/wiki/Shebang_(Unix))
line at the top of your scripts and that shell will be used. This flexibility
also means that you can use multiple shells between different spell scripts!

For example, here's how you would use Zsh instead of Bash:
```
cat << 'EOF' > spells/zsh.sh
#!/usr/bin/env zsh

set -Eeuo pipefail
VERBOSE="${VERBOSE:-""}"
if [[ "$VERBOSE" != "" ]]; then set -x; fi

echo $SHELL
EOF
```


## Handling Secrets

There is no built-in way of handling secrets when using Candalf.
However, since everything is a shell script then you can use whatever you want
to handle sensitive data!

Here's an example of using [encpipe](https://github.com/jedisct1/encpipe),
a really simple tool for symmetric key encryption/decryption.

First, let's create our encrypted data:
```bash
echo "some secret thing" | encpipe -e -p "encryption password" | base64 -w0
```

Output of this command will be a base64 encoded encrypted secret which you can
safely commit to VCS. You need to remember `encryption password` since this is
needed when applying spell in the future.

Let's create the relevant spell for using that encrypted data:
```bash
cat << 'EOF' > spells/secret.sh

#!/usr/bin/env bash 

set -Eeuo pipefail
VERBOSE="${VERBOSE:-""}"
if [[ "$VERBOSE" != "" ]]; then set -x; fi

read -rsp "Enter secrets password: " PASSWORD
echo

SECRET=$(echo "EgAAAHHp8AQhiyZqSU6ZgZg3fez34hMVI5C1OWBuo/YaWEhmfXr2eJUp1stS9qAsjDw9zQ4CdhfWjwAAAAANbk3myi1vpG2JR3wlBwcj6qob9f0HSmnjwOq0G2Kr+IUnTQg=" | \
  base64 -d | \
  encpipe -d -p "$PASSWORD")
echo "Decrypted: $SECRET"
EOF
```

Let's add it to our spell-book and cast it as any other spell:
```bash
echo "cast spells/secret.sh" >> example.org.sh

candalf example.org.sh
```

When this spell gets cast, then you will be asked for the encryption password.
In this example we just print out the decrypted data, but in the real world you
can do whatever you need to do with that data.


## Best Practices

* Write spell scripts like you would write database migrations - keep in
mind that when spell script has been cast successfully then it
will be _committed_ which means that Candalf will not cast it again.

* It is a good practice to keep spell scripts as small as possible
and as specific as possible - instead of having one big spell script which
does everything split it into multiple smaller logical ones.

* Keep in mind that spells are applied in the order of definition in the spell
book script and no spells are cast after the failing one.

* When casting of a spell fails then pay close attention at what step did it fail
because all previously executed commands will be executed again.

* Make sure that if you need to change any already cast spell scripts then pay
extra attention to any commands which should not be executed ever more than
once - maybe adding some extra `if` statement guard around these is good
enough.

* To undo a spell create a new spell which includes all the
necessary steps to revert changes done by some previous spell instead of
changing the existing spell.

* It's recommended casting spells against a local VM before running against
a production system so you can test them out on a system similar to the production environment 
before going to destroy the real one. Don't forget to make a snapshot of the VM to
roll back in case testing fails and you need to re-adjust your spell.


## Troubleshooting

Sometimes things go south. For these situations Candalf has some ways to
help you with.

You can enable `VERBOSE` mode by running `candalf` like this:
```bash
VERBOSE=1 candalf example.org.sh
```

Beware that there will be a lot of output, but hopefully you can find the
problem.

When this doesn't help or you need to understand what has happened to the
system over time you can look into server's `/var/log/candalf.log` where all
the casted spells and attempts of casting any spells have been logged.

To see all the casted spells in the past look into the server `~/.candalf/spells`
directory - there are spells with extension `.current` which include the latest
cast spell script and then spells with `.YYYYmmddHHMMSS` extension, which are
spells applied in the past. Timestamp extension reflects the time when that
spell was replaced by a new one and not a time when it was cast.


## Forcing of Casting a Spell

Sometimes there is a need to cast some alrady casted spell again. It can be
done by removing a `.current` file in the server. For example, let's imagine
that a spell `spells/system/upgrade.sh` should be cast again. Run the following
commands to do it:
```bash
ssh example.org "rm -f .candalf/spells/system/upgrade.sh.current"
candalf example.org
```


## License

Candalf is released under a *Lesser GNU Affero General Public License*, which
in summary means:

- You **can** use this program for **no cost**.
- You **can** use this program for **both personal and commercial reasons**.
- You **do not have to share your own program's code** which uses this program.
- You **have to share modifications** (e.g. bug-fixes) you've made to this
  program.

For more convoluted language, see the [LICENSE](LICENSE) file.
