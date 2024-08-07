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
* Very easy to install since there are no dependencies except a **shell** and Candalf scripts themselves;
* Spells are **cast only once** and cast again only when the spell file itself has been changed;
* It's **blazing fast** since only changed spells are sent to the server using rsync and only one ssh connection is made to cast all of them;
* Any shell is supported since spells are executed using their **shebang** line;
* Very easy to understand what Candalf does exactly since it is implemented as a **few hundred lines** of shell scripts;
* **Supports** the following operating systems:
  - Ubuntu Linux
  - FreeBSD
  - Arch Linux
  - CentOS
  - Fedora Linux
  - Alpine Linux
  - Any other similar operating system
* Adding support to a new Linux/Unix-like OS is quite easy thanks to [tests](test).


## Dependencies

To use Candalf to cast spells to a clean system, the following requirements need to be met:

* System should be running a **supported** OS;
* SSH server should be running on port **22** and it should be accessible from your machine;
* Logging in with **root password** over SSH should be allowed and enabled;
* `rsync` needs to be installed on the current system (it will be installed automatically on the remote system when needed);
* `bash` needs to be installed on the current system.

When SSH server is running on a non-standard port already and/or password login is
disabled then it is still possible to use Candalf, but some extra steps
are needed. See more in [Installation](#installation) section.


## Installation

First, clone Candalf itself on your local system:
```bash
git clone https://github.com/jarmo/candalf.git
```

```bash
sudo ln -s $(realpath candalf/candalf.sh) /usr/local/bin/candalf
```

Create a separate project/directory for your server spell scripts:
```bash
mkdir -p example/spells
```

Create your first spell scripts:
```bash
cd example

cat << 'EOF' > spells/today.sh
#!/usr/bin/env bash

test "$VERBOSE" && set -x
set -Eeo pipefail

date +"%Y-%m-%d" > ~/today
cat ~/today
EOF

chmod +x spells/today.sh

cat << 'EOF' > spells/whoami.sh
#!/usr/bin/env bash

test "$VERBOSE" && set -x
set -Eeo pipefail

whoami > ~/me
cat ~/me
EOF

chmod +x spells/whoami.sh
```

Create a script for casting all the spells (so-called spell book):
```bash
cat << 'EOF' > example-book.sh
#!/usr/bin/env bash

test "$VERBOSE" && set -x
set -Eeo pipefail

. "${CANDALF_ROOT:="."}"/lib/cast.sh

cast spells/today.sh 
cast spells/whoami.sh
EOF

chmod +x example-book.sh
```

Cast all the spells to the server at example.org:
```bash
candalf example.org example-book.sh
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

See [example](example) for a simple spell book example.


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
You should think of a remote system being a read-only system when it comes to installing new packages
or configuring anything there manually.

Spell book script of a server is a pretty simple one. Let's create one without any spells in it:
```bash
cat << 'EOF' > example-book.sh
#!/usr/bin/env bash

test "$VERBOSE" && set -x
set -Eeo pipefail

. "${CANDALF_ROOT:="."}"/lib/cast.sh

EOF

chmod +x example-book.sh
```

It's pretty straightforward - first it has a `shebang` line which instructs
Bash to be used as a running shell, then a bunch of important `set` commands (read from
the shell manual or
from [this blog post](https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/) to understand what they're for)
and `lib/cast.sh` is sourced so that a few Candalf helper functions could be used.

Now, adding spells to the spell book script is really easy too - you just need
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

test "$VERBOSE" && set -x
set -Eeo pipefail

apt update -y
apt upgrade -y

touch ~/upgrade-done
EOF

chmod +x spells/system/upgrade.sh
```

Again pretty straightforward - standard boiler-plate code in the header of the
script and then the important part of running `apt` commands for upgrading the system packages.
It's always a good idea to do this on a new system before doing anything else.

Let's add this spell into our spell book script, otherwise it will not be cast:
```bash
echo "cast spells/system/upgrade.sh" >> example-book.sh
```

Let's cast all the defined spells (we assume that Candalf itself has been installed already
as specified in the [Installation](#installation) section):
```bash
candalf example.org example-book.sh
```

If everything goes well then a SSH key is going to be created, it will be
copied to the server, SSH server will be running on a random port and password
authentication via SSH server will be disabled. There will be also a lot of output
from apt upgrading the system.

If you run the same command again then not much happens because Candalf has
already cast this spell and will not do much again. However, as soon as you
change that spell script then it will be cast again from the beginning to the
end.

**PS!** Spell book file name is used at the remote system for keeping track of
spells - if you rename it then all the spells will be applied again. Make sure
to rename all spell book directories on remote system before running candalf
again after rename!


## Casting Spells for Unprivileged Users

Since Candalf connects to the server using `root` user by default then all
spells are casted to that user. However, if you need to cast spells to other
users then this is also possible.

Here's how we would do that:
```bash
mkdir -p spells/john

cat << 'EOF' > spells/john/whoami.sh
#!/usr/bin/env bash

test "$VERBOSE" && set -x
set -Eeo pipefail

whoami > ~/me
cat ~/me
EOF

chmod +x spells/john/whoami.sh

echo "cast_as john spells/john/whoami.sh" >> example-book.sh

candalf example.org example-book.sh
```

Notice that instead of using the function `cast` we need to use the function called
`cast_as` with a user name parameter and a spell path. That's the only
difference between applying spells to the `root` or to a specific user.


## Always Casting a Spell

Sometimes there is a need to cast spell every time even when it has not been
changed. It can be easily done by prefixing `cast` or `cast_as` with `CAST_ALWAYS=1` flag:
```
CAST_ALWAYS=1 cast spells/upgrade.sh
```


## Casting Spells From Multiple Spell Books

Candalf supports casting spells from multiple spell books. For example there
might a be a base spell book, which is the same for every system and then
a specific spell book for a specific system. They can be built on top of each
other and then can be applied one by one or by specifying them one the same
command line where they will be applied from left to right:
```
candalf example.org spell-book-one/base.sh spell-book-two/specific.sh
```

Spell book names have to be unique to avoid name conflicts!


## Using Different Shells

It's possible to write spells and spell-book scripts in whatever shell you
prefer - just use an appropriate [shebang](https://en.wikipedia.org/wiki/Shebang_(Unix))
line at the top of your scripts and that shell will be used. This flexibility
also means that you can use multiple shells between different spell scripts!

For example, here's how you would use Zsh instead of Bash:
```
cat << 'EOF' > spells/zsh.sh
#!/usr/bin/env zsh

test "$VERBOSE" && set -x
set -Eeo pipefail

echo $SHELL
EOF

chmod +x spells/zsh.sh
```

This behavior adds a flexibility where some spell might install your favorite
shell to the system and then all the spells coming after it can already use
that shell.


## Handling Secrets

There is no built-in way of handling secrets when using Candalf.
However, since everything is a shell script then you can use whatever you want
to handle sensitive data!

Here's an example of using [encpipe](https://github.com/jedisct1/encpipe),
a really simple tool for symmetric key encryption/decryption.

First, let's create our encrypted data:
```bash
echo "some secret thing" | encpipe -e -p "encryption-password" | base64 -w0
```

Output of this command will be a base64 encoded encrypted secret which you can
safely commit to VCS. You need to remember `encryption-password` since this is
needed when applying spell in the future.

Let's create a spell for getting `encpipe` binary for decryption at server-side:
```bash
cat << 'EOF' > spells/system/encpipe.sh
#!/usr/bin/env bash 

test "$VERBOSE" && set -x
set -Eeo pipefail

apt update -y
git clone https://github.com/jedisct1/encpipe.git
cd encpipe
make
make install
EOF

chmod +x spells/system/encpipe.sh
```

Let's create the relevant spell for using that encrypted data:
```bash
cat << 'EOF' > spells/secret.sh
#!/usr/bin/env bash 

test "$VERBOSE" && set -x
set -Eeo pipefail

read -rsp "Enter secrets password: " PASSWORD
echo

SECRET=$(echo "EgAAAHEAVUE0ahrrdU0gEdS++89Zy8pFMhUe8lci9mdWZgfs70s9Q7Ge4pI62FcQFa5/gk5kS9oIVAAAAABSA8C6vGOpSDySUMnbwZQ58I23jXu+96bu6s7TrAzVZpknWvw=" | \
  base64 -d | \
  encpipe -d -p "$PASSWORD")
echo "$SECRET" > decrypted.secret
EOF

chmod +x spells/secret.sh
```

Let's add these spells to our spell-book and cast them as any other spells:
```bash
echo "cast spells/system/encpipe.sh" >> example-book.sh
echo "cast spells/secret.sh" >> example-book.sh

candalf example.org example-book.sh
```

When this spell gets cast, then you will be asked for the encryption password.
In this example we just print out the decrypted data, but in the real world you
can do whatever you need to do with that data.


## Environment Variables

Candalf supports passing environment variables to the remote system too.
However, not all variables are passed due to security and/or system integrity
reasons. Only variables starting with a prefix of `CANDALF_` are supported.
Here's an example of how you can pass a password for decryption of the secrets
instead of entering it from a prompt (read from [Handling Secrets](#handling-secrets)).

Let's modify our secret spell file:
```bash
cat << 'EOF' > spells/secret.sh
#!/usr/bin/env bash 

test "$VERBOSE" && set -x
set -Eeo pipefail

CANDALF_PASSWORD="${CANDALF_PASSWORD:?"CANDALF_PASSWORD is missing!"}"

SECRET=$(echo "EgAAAHEAVUE0ahrrdU0gEdS++89Zy8pFMhUe8lci9mdWZgfs70s9Q7Ge4pI62FcQFa5/gk5kS9oIVAAAAABSA8C6vGOpSDySUMnbwZQ58I23jXu+96bu6s7TrAzVZpknWvw=" | \
  base64 -d | \
  encpipe -d -p "$CANDALF_PASSWORD")
echo "Decrypted: $SECRET"
EOF
```

Note that instead of using `read` we now pass password to the `encpipe` via an
envionrment variable `$CANDALF_PASSWORD`. It is also a good practice to bail
out early with an error when that environment variable has not been set.

Now, to execute candalf just specify password on the command line like this:
```
CANDALF_PASSWORD="encryption-password" candalf example.org example-book.sh
```

## Casting Spells Locally

It's also possible to cast spells to the local system. It might be useful for
setting up your own machine.

To do this you simply need to specify `SERVER` parameter as a special parameter `localhost` or `127.0.0.1`:
```bash
sudo -H candalf localhost example-book.sh
```

Running `candalf` requires **root** permissions so prefix it with `sudo -H` when
not running as a root. Everything else is the same as running `candalf` regularly to cast spells to
remote systems via SSH.

SSH server does not need to be running to use Candalf on a local system.


## Best Practices

* Use `--dry-run` mode before casting spells for real to see what would happen
after your last changes.

* Write spell scripts like you would write database migrations - keep in
mind that when spell script has been cast successfully then it
will be _committed_ which means that Candalf will not cast it again.

* It is a good practice to keep spell scripts as small as possible
and as specific as possible - instead of having one big spell script which
does everything split it into multiple smaller logical ones.

* Keep in mind that spells are applied in the order of declaration in the spell
book script and no spells are cast after one fails.

* When casting of a spell fails then pay close attention at what step did it fail
because all previously executed commands in that spell script will be executed again on retry.

* When you need to change any spell script which has been already cast then pay
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
candalf -v example.org example-book.sh
```

Beware that there will be a lot of output, but hopefully you can find the
problem.

When this doesn't help or you need to understand what has happened to the
system over time you can look into server's `/var/log/candalf.log` where all
the casted spells and attempts of casting any spells have been logged.

To see all the casted spells in the past look into the server `~/.candalf/SPELL_BOOK/spells`
directory - there are spells with extension `.current` which include the latest
cast spell script and then spells with `.YYYYmmddHHMMSS` extension, which are
spells applied in the past. Timestamp extension reflects the time when that
spell was replaced by a new one and not a time when it was cast.


### Setting Spells as Cast

It might happen that spell will be cast half-way through and cannot be cast anymore
due to destructive commands in the beginning of a spell script. Here's one example:
```bash
cat << 'EOF' > spells/command.sh
#!/usr/bin/env bash

test "$VERBOSE" && set -x
set -Eeo pipefail

mkdir foo

wrong-command
EOF
```

When trying to cast this spell we will get an error message:
```bash
wrong-command: command not found
```

Now, if we fix that spell by replacing `wrong-command` with a correct one and
try to cast this spell again, we will get another error:
```bash
mkdir: cannot create directory ‘foo’: File exists
```

One way to fix this situation would be to add some guard statements around
destructive commands (or `mkdir -p` for this particular case), however it might
not be the best solution because it might hide some problems when applying
spells to a clean machine (maybe if that directory `foo` already exists hints at some
problem since it has been created by something else, which should not have
happened in the first place?).

To solve this situation I would recommend running commands manually and then
set that spell as never to be cast to Candalf so that it would mark it as successfully done.

To do this you have to prefix spell with `CAST_NEVER=1` flag like this:
```
CAST_NEVER=1 cast spells/command.sh
```

After running candalf then `spells/command.sh` will be marked as successfully
ran and you can remove `CAST_NEVER=1` flag.

However, using a solution like this should be a very last resort. Use a VM for
testing and its snapshot functionality to avoid situations like this in the
first place!

You can also use `CAST_NEVER` flag as a feature toggle between different
systems like this:
```
DISABLE_SPELL="${CANDALF_DISABLE_SPELL:-""}"
CAST_NEVER="$DISABLE_SPELL" cast spells/command.sh
```

Now, running a candalf with `CANDALF_DISABLE_SPELL` environment variable will
not run any commands inside `spells/command.sh`:
```
$ CANDALF_DISABLE_SPELL=1 candalf example.org example-book.sh
```

Refer to [Environment Variables](#environment-variables) to understand how to
pass environment variables to spell books/spells.


## Development

Development of Candalf is easy - just modify scripts in this repository and
execute `candalf.sh` directly instead of using a globally installed `candalf`
command.


## Testing

All the shell scripts in here are checked with [ShellCheck](https://www.shellcheck.net/).

Candalf also has tests and they are being run inside virtual machines (VM).
See all the existing tests inside [test](test) directory.

Some prerequisites need to be fulfilled before running tests:

1. Install [ShellCheck](https://www.shellcheck.net) - recommended way of doing
   that is via [asdf](http://asdf-vm.com/) by installing correct version
   described in [.tool-versions](.tool-versions).
2. Install [VirtualBox](https://www.virtualbox.org).
3. Install [Vagrant](https://www.vagrantup.com).
4. Modify `/etc/hosts` so that `candalf.test` would point against your local machine:
```bash
$ echo "127.0.0.1 candalf.test" | sudo tee -a /etc/hosts
```

To run all the tests against all supported virtual machines (see [Makefile](Makefile)),
execute the following command:
```
$ make test
```

To run a single test against all supported virtual machines, execute the
following command:
```
$ make test-one TEST=test/test-example.sh
```

To execute a single test against an Ubuntu Linux VM:
```
$ test/test-[NAME].sh
```

To execute a single test against FreeBSD VM:
```
$ VAGRANT_BOX="generic/freebsd13" test/test-[NAME].sh
```

Use any other `VAGRANT_BOX` environment value to run tests against that VM.

Tests have been run on Ubuntu Linux and might not work from anywhere else.


### Writing and Troubleshooting Tests

All test file names need to be prefixed with `test-` and they have to reside
under [test](test) directory. Easiest way to write a test is to copy an existing
test into a new test file and then modify it according to your needs.

Running any test creates a VM from scratch, creates a snapshot and restores to
that snapshot when multiple tests are run. After all tests have been run or
test has failed, that VM will be destroyed.
This is good practice to avoid creating tests which depend on each-other.

However during troubleshooting or writing new tests this approach uses too much
time. For this there is an environment variable `KEEP_VM=1` which, when enabled,
does not destroy VM nor restore it from the snapshot. This allows instantaneous
test executions. Use it like this:
```bash
$ KEEP_VM=1 ./test/test-example.sh
```

Having this flag enabled for multiple tests doesn't make sense
since they will fail due to messing VM up for eachother.

Don't forget to run test without this flag to run against a clean VM afterwards.


#### Verbose Tests

`VERBOSE=1` flag works also when running tests. Use it when can't immediately
understand why your test behaves as it is behaving:
```bash
$ VERBOSE=1 make test
```

or

```bash
$ VERBOSE=1 test/test-example.sh
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
