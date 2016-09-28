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

Now we will create two partitions, one for `/boot` and one for `lvm`. Following
is a list of what to enter. `<CR>` denotes pressing the enter key.

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
very important. We are going to encrypt the entire `lvm` partition using `luks`.
The frontend tool to be used for this is `cryptsetup`:

```
cryptsetup --cipher aes-xts-plain64 --hash sha512 --key-size 256 luksFormat /dev/sda2`
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
initialized here. ZFS requires custom kernel modules which will be built later.

#### Mount the filesystems
Next up is mounting all filesystems so we can install files to them. First, we
mount the root filesystem:

```
mount /dev/mapper/krata0-root /mnt/gentoo
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
Before we get to the configuration part, we should `chroot` into the system.
This allows you to enter your new Funtoo installation before it can properly
boot. If your system ever breaks and you are unable to boot into it anymore, you
can redo the mounting section of this guide and this chrooting section to get
into it and resolve your issues.

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
favourite editor. Funtoo comes with `vi`, `nano` and `ed` by default. `ed` is
recommended as the standard editor. After opening the file, change the
`location` key to point to `/usr/portage/funtoo`.

When you have modified `/etc/portage/repos.conf/gentoo` (or not, if you do not
want to change this default), continue to download your first version of the
portage tree:

```
emerge --sync
```

Everytime you want to update your system, you will have to do an `emerge --sync`
to update the portage tree first. It is managed by `git`, which can bring some
side effects. The most notable one is that the tree will grow over time with old
commit data. If you wish to clean this up, simply
`rm -rf /usr/portage/* && emerge --sync` to regenerate it from scratch

#### Setting up your system settings
#### Preparing your first kernel
#### Installing a bootloader
#### Set your system profile
#### Installing supporting software
This is software you will more than likely need on any standard system. If
you're an advanced user you can decide to skip this and make your own choices,
otherwise it is recommended to install this software as well.

```
emerge connman sudo vim
```

#### Configuring supporting software

##### connman

##### sudo

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

## Final thoughs

[sysrescuecd]: http://www.system-rescue-cd.org/SystemRescueCd_Homepage
[osuosl]: http://ftp.osuosl.org/pub/funtoo/distfiles/sysresccd/systemrescuecd-x86-4.7.1.iso
[funtoo]: http://build.funtoo.org/distfiles/sysresccd/systemrescuecd-x86-4.7.1.iso
[funtoo-build]: http://build.funtoo.org/

