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
`/mnt/cdrom/usb_inst.sh`. Select the right device and wait for the installer to
finish up.

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
The first part is to setup partitions. This can be done by calling `gdisk
/dev/sda`. Let us wipe the entire disk and start with a clean slate. You can do
this by typing `o` and pressing enter. When asked wether you are sure, type `y`
and enter again.

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
#### Set up LVM
#### Create filesystems
#### Mount the filesystems

### Initial setup
#### Download a stage 3 tarball
#### Install the stage 3 tarball

### System configuration
#### Chrooting
#### Download the portage tree
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

#### Create a user
Create a user for yourself on the system. You can use any other value for `tyil`
if you so desire:

```
useradd -G wheel tyil
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

