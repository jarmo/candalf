# Provisioner

Provisioner is a simple tool that helps to orchestrate Unix-like system
configuration/setup/management using SSH.

There are many tools that do a similar
thing (like [Ansible](https://www.ansible.com/), [Chef](https://www.chef.io/), [Puppet](https://puppet.com/) etc.) however
Provisioner sets itself apart from them by being much easier to learn and use since there is no need to learn yet another
specific DSL language.

Provisioner uses shell scripts to do everything which means that
all is really explicit and really easy to troubleshoot manually in case of any
problems.


## Features

* Very **easy** to learn and use since the only knowledge required is writing regular `bash` scripts;
* Very **flexible** - everything you can do manually from command line can be also done with Provisioner;
* Migrations are **applied only once** and re-applied only when the migration file itself has been changed;
* It's **blazing fast** since migrations are sent to the server using rsync and only one ssh connection is made to apply all the migrations;
* Very easy to understand what Provisioner does exactly since it is implemented as **~150 lines** of shell scripts;
* Supports **Debian** and **BSD** systems.


## Dependencies

To use Provisioner to provision a clean system, these requirements need to be
met:

* System should be running **Debian** or **BSD** OS (adding a new Unix-like system support is pretty easy too);
* SSH server should be running at port **22** and it should be accessible from your system;
* Logging in with **root password** over SSH should be allowed and enabled;
* `rsync` needs to be installed on the current system (it will be installed automatically on the server when needed).

When SSH server is running on a non-standard port already and/or password login is
disabled then it is still possible to use Provisioner, but some extra steps
are needed. See more in [Installation](#installation) section.


## Installation

First, clone provisioner:
```bash
git clone https://github.com/jarmo/provisioner.git
```

Create a separate directory where server migration scripts will be:
```bash
mkdir -p example.org-provisioning/migrations
```

Reference `provision.sh` from that directory so that it would be possible to
execute it directly from your `example.org-provisioning` directory:
```bash
cd example.org-provisioning
ln -s /absolute/path/to/provisioner/provision.sh
```

Create your first `migration` scripts:
```bash
cat << 'EOF' > migrations/now.sh
#!/usr/bin/env bash

set -e
if [[ "$VERBOSE" != "" ]]; then set -x; fi

date > ~/now
cat ~/now
EOF

cat << 'EOF' > migrations/me.sh
#!/usr/bin/env bash

set -e
if [[ "$VERBOSE" != "" ]]; then set -x; fi

id -un > ~/me
cat ~/me
EOF
```

Create a script for applying all migrations:
```bash
cat << 'EOF' > example.org.sh
#!/usr/bin/env bash

set -e
if [[ "$VERBOSE" != "" ]]; then set -x; fi

. lib/remote.sh

apply migrations/now.sh 
apply migrations/me.sh
EOF
```

PS! File name should include the actual domain name for the server (in this
case it's `example.org`) because Provisioner uses that name to connect to the
correct server.

Apply migrations to the server:
```bash
./provision.sh example.org.sh
```

During the first run you will be asked for the remote system root password a couple of times to
create a SSH key and copy it to the server. After that initial run of Provisioner, SSH
server will be running on a random port, password authentication via SSH will
be disabled and a SSH configuration will be created locally into `~/.ssh/config` under the server domain name Host key.

For the example above, there will be an entry in the `~/.ssh/config` like the
following:
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
name as their file names.


### Installation With Preconfigured SSH Server

When server does not have password authentication enabled over SSH then it's
easy to start using Provisioner too. Just make sure that you have
private/public key under `~/.ssh` having same name as your server domain name
and create a SSH configuration similar to shown above.
This will make Provisioner to assume that SSH authentication with a public key
has been already completed and you can use it normally.


## Provisioning

To provision a system a provisioning script is required. This is basically a script which describes
everything that should be done on a remote system to configure and set it up - think of installing
all necessary dependencies and configuring them as you would do manually.

Good practice would be not to do any changes manually on the remote system, but
only use migration files and keep these in the VCS too for having a better understanding
of the remote system (and for a good disaster recovery/scaling reasons).
You should think of a remote system being a read-only system when it comes to installing new packages or configuring anything there.

Provisioning file itself is pretty simple. Let's create one without any
migrations in it:
```bash
cat << 'EOF' > example.org.sh
#!/usr/bin/env bash

set -e
if [[ "$VERBOSE" != "" ]]; then set -x; fi

. lib/remote.sh
EOF
```

It's pretty straightforward - it has `set -e` automatically enabled to exit
provisioning as soon as some command fails. `set -x` will be enabled when
`VERBOSE` mode has been turned on for easier troubleshooting
and `lib/remote.sh` is sourced so that a few Provisioner helper functions could be used.

Now, adding migrations to the provisiong script is really easy too - just need
to execute function `apply` with a parameter to migration file. Migration files
can be placed anywhere but the argument to `apply` function should have
a relative path to the file. It's a good practice to put them under directory
called `migrations` and add there separate subdirectories for different
dependencies, for example `migrations/nginx` directory could have files called
`nginx.sh` and `firewall.sh` which would install nginx and configure firewall
to allow traffic to ports 80/443 respectively. Let's add one migration to the
provisioner, which updates and upgrades all packages on the remote Debian system:

```
mkdir -p migrations/system

cat << 'EOF' > migrations/system/upgrade.sh
#!/usr/bin/env bash

set -e
if [[ "$VERBOSE" != "" ]]; then set -x; fi

apt update -y
apt upgrade -y
EOF
```

Again, pretty straightforward - standard statements for `set -e` and `set -x` are added
and then the important part of running `apt` commands for upgrading the system packages.
It's always a good idea to do this on a new system before doing anything else.

Let's add this migration into our provisioning script otherwise it will
not be applied:
```bash
echo "apply migrations/system/upgrade.sh" >> example.org.sh
```

Let's apply migrations (we assume that a symlink to `provision.sh` has been
done already as specified in the [Installation](#installation) section):
```bash
./provision.sh example.org.sh
```

If everything goes well then a SSH key is going to be created, it will be
copied to the server, SSH server will be running on a random port and password
authentication via SSH server is disabled. There will be also a lot of output
from apt upgrading the system.

If you run the same command again then not much happens because Provision has
already applied this migration and will not do much. However, as soon as you
change that migration script then it will be reapplied from the beginning to the
end.


## Best Practices

* Write migration scripts like you would write database migrations - keep in
mind that when migration script has been applied successfully then it
will be _committed_ which means that Provisioner will not apply it again.

* It is a good practice to keep migration scripts as small as possible
and as specific as possible - instead of having one big migration script which
does everything split it into multiple smaller logical steps.

* Keep in mind that migrations are applied in the order of definition in the provision
script and no migrations are applied after the failing one.

* When applying of a migration fails then pay close attention at what step did it fail
because all previously executed commands will be executed again.

* Make sure that if you need to change any already applied migration script then pay
extra attention to any commands which should not be executed ever more than
once - maybe adding some extra `if` statement guard around these is good
enough.

* To roll back a migration create a new migration which includes all the
necessary steps to undo changes done by some previous migration instead of
changing the existing migration.

* It's recommended applying migrations against a local VM before running against
a production system so you can test them out on a system similar to production before
going to destroy the real one. Don't forget to make a snapshot of the VM to
roll back in case testing fails and you need to re-adjust your migration.


## Troubleshooting

Sometimes things go south. For these situations Provisioner has some ways to
help you with.

First would be to enable `VERBOSE` mode by running `provision.sh` like this:
```bash
VERBOSE=1 ./provision.sh example.org.sh
```

Beware that there will be a lot of output, but hopefully you can find the
problem.

When this doesn't help or you need to understand what has happened to the
system over time you can look into server's `/var/log/provisioner.log` where all
the migrations and migration attempts have been logged.

To see all the applied migrations in the past then look into the server `~/.provisioner/migrations`
directory - there are migrations with extension `.current` which include the latest
applied migration script and then migrations with `.YYYYMMDDHHMMSS` extension, which are
migrations applied in the past. Timestamp extension reflects the time when that
migration was replaced by a new one and not a time when it was applied.


## License

Provisioner is released under a *Lesser GNU Affero General Public License*, which
in summary means:

- You **can** use this program for **no cost**.
- You **can** use this program for **both personal and commercial reasons**.
- You **do not have to share your own program's code** which uses this program.
- You **have to share modifications** (e.g. bug-fixes) you've made to this
  program.

For more convoluted language, see the [LICENSE](LICENSE) file.
