# Install Funtoo

## Foreword

## Assumptions

## Installing Funtoo

### The live environment
Before we can get started with setting up the system, we will need something to
set it up with. We will be using a live environment for this purpose. My
personal choice for this task is [the Gentoo-based SystemRescueCD][sysrescuecd].

You can use any other live environment your prefer, however, this tutorial will
only guide you into preparing the System Rescue CD.

#### Getting the live USB image
You can download the System Rescue CD at one of the following locations:

- [Funtoo][Funtoo]
- [Osuosl][osuosl]

#### Setting up the live USB
After downloading the image, mount it somewhere:

```
mount path/to/sysrescuecd.iso /mnt/cdrom
```

Once it is mounted, you can run the installer bundled with the image by running

```
/mnt/cdrom/usb_inst.sh
```

Select the right device and wait for the installer to finish up.

#### Booting the USB
To begin using the live environment so you can install something with it, boot
it up. Make sure the USB is in the machine, and reboot it. Enter the BIOS/UEFI
settings and make sure to either make the USB device a higher boot priority, or
select it to be the boot device for one boot. The availability and location of
these options differs per machine, so be sure to check the manual or look around
online for instructions if it is not clear to you.

### Hardware preparation
The hardware we are installing on needs to be prepared. This could mean manually
configuring your hardware RAID if you use this and configuring other exotic
setups. This tutorial will not go into details for such setups, as there is a
near infinite amount of possible options. Instead, we will stick to simply
configuring your storage device.

The size of your storage device should be at least 35GB to be safe and have some
space for personal data. The partitioning layout we are aiming for is the following:

```
DEVICE                 FILESYSTEM  SIZE  MOUNTPOINT
sda
  sda1                 fat32        2GB  /boot
  sda2                 lvm
    funtoo0-root       xfs          8GB  /
    funtoo0-home       zfs               /home
    funtoo0-sources    ext4         3GB  /usr/src
    funtoo0-portage    reiserfs     2GB  /usr/portage
    funtoo0-swap       swap
    funtoo0-packages   xfs         10GB  /var/packages
    funtoo0-distfiles  xfs         10GB  /var/distfiles
```

If you already an advanced user, you are of course free to diverge from the
guide here.

#### Partition the drive
The first part is to setup partitions. This can be done by calling

```gdisk /dev/sda```

Let us wipe the entire disk and start with a clean slate. You can do this by
typing `o` and pressing enter. When asked wether you are sure, type `y` and
enter again.

Now we will create two partitions, one for `/boot` and one for
[`lvm`][wikipedia-lvm]. Following is a list of what to enter. `<CR>` denotes
pressing the enter key.

- `n` `<CR>`
- `<CR>`
- `<CR>`
- `+500M` `<CR>`
- `EF00` `<CR>`

- `n` `<CR>`
- `<CR>`
- `<CR>`
- `<CR>`
- `<CR>`

#### Setting up encryption
Any system should be safe. Encryption is just a small part, but in my opinion
very important. We are going to encrypt the entire `lvm` partition using
[`luks`][wikipedia-luks]. The frontend tool to be used for this is
[`cryptsetup`][wikipedia-cryptsetup]:

```
cryptsetup --cipher aes-xts-plain64 --hash sha512 --key-size 256 luksFormat /dev/sda2
```

`cryptsetup` will ask you for a passphrase. Make sure to use a good one,
preferably at least 20 characters in length.

Once the partition has been encrypted, open the device so it can be used by
invoking `cryptsetup luksOpen /dev/sda2 dmcrypt_lvm`.

#### Set up LVM
Once the encrypted partition has been unlocked, we can setup `lvm` on it. To
initialize an lvm volume on this partition, run the following:

```
pvcreate /dev/mapper/dmcrypt_lvm
vgcreate funtoo0 /dev/mapper/dmcrypt_lvm
```

The lvm volume has now been prepared, and we can start adding volumes to it to
be used as partitions. It is recommended to have a swap partition as well. The
size of this partition depends on the amount of RAM you have available. Due to
my availability to big disks, I generally opt for a swap partition the same size
as my total RAM in the machine. To make the tutorial work for this as well, a
subshell is called to figure out the size of the swap partition.

```
lvcreate -L8G -n root funtoo0
lvcreate -L3G -n sources funtoo0
lvcreate -L2G -n portage funtoo0
lvcreate -L10G -n packages funtoo0
lvcreate -L10G -n distfiles funtoo0
lvcreate -L$(free | grep -i mem: | awk '{print $2}') -n swap funtoo0
lvcreate -l 100%FREE -n home funtoo0
```

#### Create filesystems
Now we are ready to create usable filesystems on the partitions:

```
mkfs.vfat -F32 /dev/sda1
mkfs.xfs /dev/mapper/funtoo0-root
mkfs.xfs /dev/mapper/funtoo0-packages
mkfs.xfs /dev/mapper/funtoo0-distfiles
mkfs.reiserfs /dev/mapper/funtoo0-portage
mkfs.ext4 /dev/mapper/funtoo0-sources
mkswap /dev/mapper/funtoo0-swap
```

If you're thinking at this point "where's my home partition?", it's not
initialized here. [ZFS][wikipedia-zfs] requires custom kernel modules which will
be built later, after the initial kernel has been compiled.

#### Mount the filesystems
Next up is mounting all filesystems so we can install files to them. First, we
mount the root filesystem:

```
mount /dev/mapper/funtoo0-root /mnt/gentoo
```

Now we can add some directories for the other mountpoints. This can be done in
one well-made `mkdir` invocation:

```
mkdir -p /mnt/gentoo/{boot,home,usr/{portage,src},var/{tmp,distfiles,packages},tmp}
```

Next we can mount all other mountpoints on the new directories:

```
mount /dev/sda1 /mnt/gentoo/boot
mount /dev/mapper/funtoo0-portage /mnt/gentoo/usr/portage
mount /dev/mapper/funtoo0-sources /mnt/gentoo/usr/src
mount /dev/mapper/funtoo0-distfiles /mnt/gentoo/var/distfiles
mount /dev/mapper/funtoo0-packages /mnt/gentoo/var/packages
```

Let's also enable swap and ramdisks for the temporary storage directories:

```
swapon /dev/mapper/funtoo0-swap
mount -t tmpfs none /mnt/gentoo/tmp
mount --rbind /mnt/gentoo/tmp /mnt/gentoo/var/tmp
```

### Initial setup
Now that all mountpoints have been set up, installation of the actual OS can
begin. This is done by downloading a "stage 3" tarball containing a bare minimal
Funtoo installation and extracting it with the right options.

The stage 3 tarball can be downloaded from [build.funtoo.org][funtoo-build]. It
is easiest to download and extract the tarball in the root filesystem, so let's
do that:

```
cd /mnt/gentoo
wget http://build.funtoo.org/funtoo-current/x86-64bit/generic_64/stage3-latest.tar.xz
tar xpf stage3-latest.tar.xz
```

Once extraction is complete, you can opt to delete the tarball as it is no
longer needed at this point. You can delete it by invoking `rm stage3-latest.tar.gz`.

### System configuration
You now have a bare Funtoo installation ready on your machine. But before you
can actually use it, you should do some configuration.

#### Chrooting
Before we get to the configuration part, we should [`chroot`][wikipedia-chroot]
into the system. This allows you to enter your new Funtoo installation before it
can properly boot. If your system ever breaks and you are unable to boot into it
anymore, you can redo the mounting section of this guide and this chrooting
section to get into it and resolve your issues.

The chrooting requires a couple extra mounts, so the chroot can interface with
the hardware provided by the system above it:

```
mount -t proc none proc
mount --rbind /dev dev
mount --rbind /sys sys
```

Once these mountpoints are set, you can enter your Funtoo installation using the
following:

```
chroot . bash -l
```

#### Set up the portage tree
The portage tree is a collection of files which are used by the package manager
to find out which software it can install, and more importantly, how to install
it.

The default location in Funtoo for your portage tree is in `/usr/portage`.
However, as I use multiple sources for my portage tree, I prefer to set it up
under `/usr/portage/funtoo`. This is not a required step, but advised nonetheless.

In order to change this, open up `/etc/portage/repos.conf/gentoo` in your
favourite editor. Funtoo comes with [`vi`][wikipedia-vi],
[`nano`][wikipedia-nano] and [`ed`][wikipedia-ed] by default. `ed` is
recommended as the standard editor. After opening the file, change the
`location` key to point to `/usr/portage/funtoo`.

When you have modified `/etc/portage/repos.conf/gentoo` (or not, if you do not
want to change this default), continue to download your first version of the
portage tree:

```
emerge --sync
```

Everytime you want to update your system, you will have to do an `emerge --sync`
to update the portage tree first. It is managed by [`git`][wikipedia-git], which
can bring some side effects. The most notable one is that the tree will grow
over time with old commit data. If you wish to clean this up, simply
`rm -rf /usr/portage/* && emerge --sync` to regenerate it from scratch

#### Setting up your system settings
In order to make the system work properly, some setup has to be performed. This
will involve editing some text files, for which you can use your favourite
editor again.

##### /etc/fstab
We will begin with the most important one, `/etc/fstab`. This file holds
information on your mountpoints. Some of the mountpoints are best configured
with UUIDs, because the device enumeration can sometimes differ. If you have
multiple storage devices in your system, this could as well be a hard
requirement. UUIDs are unique to each storage device, so you will have to figure
out your UUIDs yourself. You can do this by running `lsblk -o +UUID`. Take note
of the UUID of your boot device.

Once you know the UUID, open up `/etc/fstab` with whatever editor you feel
comfortable with and make it look like the following block of text. Do not
forget to update the UUIDs!

```
# boot device
/dev/sda1  /boot  vfat  noauto,noatime  1 2

# lvm volumes
/dev/mapper/funtoo0-root       /               xfs       rw,relatime,data=ordered  0 1
/dev/mapper/funtoo0-portage    /usr/portage    reiserfs  defaults                  0 0
/dev/mapper/funtoo0-sources    /usr/src        ext4      noatime                   0 1
/dev/mapper/funtoo0-packages   /var/packages   xfs       defaults                  0 1
/dev/mapper/funtoo0-distfiles  /var/distfiles  xfs       defaults                  0 1

# ramdisks
tmpfs  /tmp  tmpfs  defaults  0 0

# swap
/dev/mapper/funtoo0-swap  none  swap  defaults  0 0

# binds
/tmp  /var/tmp  none  rbind  0 0
```

##### /etc/localtime
The localtime comes next. This is to make sure your time is set correctly. An
incorrect time can cause issues such as secure connections failing. To set your
localtime, all you need to do is create a symlink. The file you need to symlink
to is stored in `/usr/share/zoneinfo`. The files are sorted by continent. As
someone who lives in the Netherlands, I'd use
`/usr/share/zoneinfo/Europe/Amsterdam`:

```
ln -fs /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime
```

It is important to also correctly set your hardware clock, in case it is off.
Check if your time and date are correct by invoking `date`. If these settings
are correct, you can skip towards the next heading. Otherwise, keep on reading
this bit.

To set the correct time, you can use the `date` utility again. When invoked with
an argument in the form of `MMDDhhmmYYYY`, it will set the date and time instead
of check it. The following command would set the date to the first of October
2016, and the time to 17:29:

```
date 011017292016
```

After you correctly set the date and time to whatever it currently is, sync it
to the hardware clock so it is correct across reboots:

```
hwclock --systohc
```

##### /etc/portage/make.conf
Another important part to configure is the `make.conf` file. This file contains
settings for portage and some options for compilers. This file can also be made
a directory. This way, you can split off your configs into multiple files for
easier maintainance. The files will be loaded alphabetically. The way you set it
up is completely up to you, though I would recommend removing the default
`/etc/portage/make.conf` and making it a directory instead.

Once you have decided how to setup your make.conf, it is time to add some data
in the file(s). Following is a list of useful variables to set up, with a block
containing my own settings for it. You can copy these for yourself, or dig
aroudn some manpages to find out what you exactly want yourself.

###### USE
`USE` holds global USE flags. These are used to configure your packages. You can
turn features on and off using these, and the ebuilds will configure the
packages to enable or disable these features.

```
USE="
    ${USE}
    alsa
    gtk
    gtkstyle
    infinality
    vim-syntax
    zsh-completion
    -pulseaudio
    -systemd
    -gnome
    -kde
"
```

###### FEATURES
The `FEATURES` variable allows enabling of various portage features. Mine are
setup to drop privileges so root is used as little as possible and to do as much
parallel as possible to speed up the process. Additionally, I use the `buildpkg`
feature to build binary packages for use on other systems. This can save you a
great deal of time if you have multiple systems running Funtoo.

```
FEATURES="
    ${FEATURES}
    buildpkg
    network-sandbox
    parallel-fetch
    parallel-install
    sandbox
    userfetch
    userpriv
    usersandbox
    usersync
"
```

###### EMERGE_DEFAULT_OPTS
`EMERGE_DEFAULT_OPTS` can be used to add some flags to every emerge you invoke.
This way you can force emerge to always ask for confirmation.

```
EMERGE_DEFAULT_OPTS="
    ${EMERGE_DEFAULT_OPTS}
    --alert
    --ask
    --binpkg-changed-deps=y
    --binpkg-respect-use=y
    --keep-going
    --tree
    --usepkg
    --verbose
"
```

###### C/XXFLAGS
The `CFLAGS` and `CXXFLAGS` variables hold compiler-specific options. It is
**very** important to not use newlines in these two, as they will break `cmake`.
Other than that, it is just a regular shell variable like the others.

```
CFLAGS="-O2 -pipe"
CXXFLAGS="-O2 -pipe"
```

###### ACCEPT_LICENSE
This variable is not as important as the others. You can even opt to leave it
out completely. If, however, you wish to limit portage to only install free
software (free as in freedom, not gratis), you can set it to the same value as
me. Do note that if you use this, you will need to setup the
`/etc/portage/package.license` as well.

```
ACCEPT_LICENSE="
    -*
    @FREE
"
```

###### MAKEOPTS
`MAKEOPTS` are the arguments passed to `make`. This can be used to instruct
`make` to use multiple threads when compiling software. The amount of threads
can be set with the `-j` flag. The general rule of thumb for this is to use
`$(($(nproc) + 1))`.

```
MAKEOPTS="
    -j9
"
```

###### PKG/DISTDIR
The `PKGDIR` and `DISTDIR` variables set the location to store binary packages
after building, and the location to store distfiles. In order to use the
`/var/distfiles` and `/var/packages` partitions, these must be set.

```
DISTDIR=/var/distfiles
PKGDIR=/var/packages
```

##### /etc/portage/package.mask
Like the `make.conf` file, `package.mask` can be made a directory containing
seperate files.

The `package.mask` file(s) allow you to "mask" packages, instructing portage to
ignore these. It can also let you mask certain versions of packages. This way
you can skip a broken version or stick to a certain version for whatever reason.
Since this tutorial uses ZFS, there is such a reason to do exactly that.

ZFS requires a Linux at version 4.4 or lower. The latest kernel is much higher
than that, so it is necessary to mask newer kernel versions. This is a single
line of configuration, and as such can be done without a fancy editor. Simply
invoke the following magic:

```
mkdir -p /etc/portage/package.mask
echo ">sys-kernel/*-sources-4.4.6" > /etc/portage/package.mask/20-zfs.mask
```

##### /etc/portage/package.license
This file can be setup as a directory too, just like `make.conf` and
`package.mask`. Using this file or directory you can add per-package license
exceptions. This is therefore only needed if you setup a strict license limit.
The kernel comes with some sources under the `freedist` license, which is not
part of `@FREE`. As such, if you want to install kernel sources you will have to
make an exception for this license on this package.

```
mkdir -p /etc/portage/package.license
echo "sys-kernel/* freedist" # TODO: check if this works
```

##### /etc/conf.d/hostname
As one of the last files to setup, the hostname should be set in
`/etc/conf.d/hostname`. The `hostname` variable in this file should be set to
the hostname of the machine. You can pick any name you like, but should be
unique across your network.

#### Preparing your first kernel
Every system needs a kernel, a piece of software to interface with the hardware.
Funtoo, like every GNU+Linux distribution, uses the Linux kernel for this task.

For this task, you will first need to decide on a source set to use. All source
sets share the same base, but they have different patches applied. It is
recommended to use `sys-kernel/gentoo-sources`. If this isn't bleeding edge
enough, you can use `sys-kernel/git-sources` instead. If you just want the
latest official kernel without the gentoo patchset, pick
`sys-kernel/vanilla-sources`. No matter which source set you use, the
compilation and installation process remains the same.

Install whichever source set you want to use, this guide will use
`sys-kernel/gentoo-sources`. In order to save some yes-pressing later on, the
`emerge` command here will install some additional packages which are needed for
the system to function properly.

```
emerge boot-update cryptsetup lvm2 gentoo-sources
genkernel --menuconfig --lvm --luks all
```

The `genkernel` command will run the kernel menuconfig utility. If you have
exotic hardware that needs special support, this is the place to enable it. The
defaults are sane for most systems. If you have nothing to configure here, just
exit the menuconfig and let `genkernel` build a custom kernel and initramfs for
you.

#### Setup ZFS
The kernel is now installed at `/boot`, and all the required parts to build
custom kernel modules are available. This means it is now possible to build the
ZFS modules.

First install the kernel module, then format the partition, and configure zfs to
work with it.

```
emerge zfs
modprobe zfs # TODO: check if this part and further actually works in the chroot
zpool create funtooz /dev/sda
zfs create -o mountpoint=/home funtooz/home
```

#### Installing a bootloader
Before building your kernel, `boot-update` was installed. This pulls in
[`grub`][wikipedia-grub], the recommended bootloader for Funtoo. It doesn't
require a lot of configuration thanks to the `boot-update` script, which will
configure `grub` for you.

Before running the script, there's one place to update as this setup uses `luks`
and `lvm`.

Open up `/etc/boot.conf` in your favourite editor and let the file display
something like this:

```
boot {
    generate grub
    default "Funtoo GNU+Linux"
    timeout 3
}

"Funtoo GNU+Linux" {
    kernel kernel[-v]
    initrd initramfs[-v]
    params += crypt_root=/dev/sda2 real_root=/dev/mapper/funtoo0-root rootfstype=xfs dolvm
}
```

Now that `boot-update` is configured, install `grub` as an UEFI bootloader and
generate the configs for it using `boot-update`.

```
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id="Funtoo GNU+Linux" --recheck /dev/sda
boot-update
```

#### Set your system profile
Your system is now ready to boot and use. However, some things are still not
configured. These can in some cases be configured after rebooting, but it is
recommended to fix it all up now. The first part is setting your system profile.

For a full list of settings, check `epro list`. Maybe you want to use this
system as something other than a workstation, or want to enable the `gnome`
mix-in.

To get the same profile settings as I use for my work environments, run the
following:

```
epro flavor workstation
epro mix-ins +no-systemd
```

#### Running the first full system update
The stage 3 tarball may have been the latest, but it might still have some
slightly outdated packages. In addition, now that your system profile is set up,
some applications may be configured to have different feature sets enabled. To
make sure everything is in the best possible state, it is recommended to run a
full system update now. Since some of our options are already set as
`EMERGE_DEFAULT_OPTS`, this is as simple as

```
emerge -uDN @world
```

#### Installing supporting software
This is software you will more than likely need on any standard system. If
you're an advanced user you can decide to skip this and make your own choices,
otherwise it is recommended to install this software as well.

```
emerge connman sudo vim linux-firmware
```

#### Configuring supporting software
Some of the supporting software has to be turned on explicitly or have a
configuration file tweaked. If you opted to not use a given recommended package,
you can skip the section with the same name.

##### connman
[`connman`][wikipedia-connman] is a simple **conn**ection **man**ager. It's
lightweight, fast and does its job pretty well. To enable this service at boot,
run

```
rc-update add connman default
```

If you want to setup wireless connection authentication credentials, read up on
`man connman-service.conf`.

##### sudo
The [`sudo`][wikipedia-sudo] utility allows certain users, based on their
username or groups they belong to, access to privileged commands. It can also be
used to run a command as a different user. The most basic setup allows people
from the `wheel` group to execute commands normally reserved for `root`.

Because sudo is a critical utility, it comes with its own editor that basically
just wraps your preferred editor in a script that will complain if the
configuration is wrong. To use this tool, invoke

```
visudo
```

Scroll to the line which contains `# %wheel ALL=(ALL) ALL`, and remove the `# `.

#### Create a user
Create a user for yourself on the system. You can use any other value for `tyil`
if you so desire:

```
useradd -m -g users -G wheel tyil
```

The `-G wheel` part is optional, but recommended if you wish to use this account
for administrative tasks. This option adds the user to the `wheel` group, which
will allow the user to execute root commands using `sudo`.

#### Set passwords
We probably want to be able to login to the system as well. By default, users
without passwords are disabled, so we'll need to set a password for the users we
want to be able to use:

```
passwd root
passwd tyil
```

If you used a different username than `tyil`, be sure to change it here as well.

## Final thoughts

[funtoo-build]: http://build.funtoo.org/
[funtoo]: http://build.funtoo.org/distfiles/sysresccd/systemrescuecd-x86-4.7.1.iso
[osuosl]: http://ftp.osuosl.org/pub/funtoo/distfiles/sysresccd/systemrescuecd-x86-4.7.1.iso
[sysrescuecd]: http://www.system-rescue-cd.org/SystemRescueCd_Homepage
[wikipedia-chroot]: https://en.wikipedia.org/wiki/Chroot
[wikipedia-connman]: https://en.wikipedia.org/wiki/ConnMan
[wikipedia-cryptsetup]: https://en.wikipedia.org/wiki/Dm-crypt#cryptsetup
[wikipedia-ed]: https://en.wikipedia.org/wiki/Ed_(text_editor)
[wikipedia-git]: https://en.wikipedia.org/wiki/Git
[wikipedia-grub]: https://en.wikipedia.org/wiki/GNU_GRUB
[wikipedia-luks]: https://en.wikipedia.org/wiki/Linux_Unified_Key_Setup
[wikipedia-lvm]: https://en.wikipedia.org/wiki/Logical_Volume_Manager_(Linux)
[wikipedia-nano]: https://en.wikipedia.org/wiki/GNU_nano
[wikipedia-sudo]: https://en.wikipedia.org/wiki/Sudo
[wikipedia-vi]: https://en.wikipedia.org/wiki/Vi
[wikipedia-zfs]: https://en.wikipedia.org/wiki/ZFS

