# dm-crypt-home
dm-crypt scripts for per-user encrypted home directories with systemd

## Idea

This project helps to ease installation and configuration for per-user encrypted home directories with [cryptsetup](https://gitlab.com/cryptsetup/cryptsetup), [systemd](https://www.freedesktop.org/wiki/Software/systemd/) and [keyutils](http://people.redhat.com/~dhowells/keyutils/).

For this setup to work you will need a single volume group where each user will have it's own LUKS-encrypted logical volume.

For example, given a volume group __MyVG__ and two users __foo__ (with ID 1000) and __bar__ (with id 1001) you will need two logical volumes ``/dev/MyVG/home_1000`` (for __foo__) and ``/dev/MyVG/home_1001`` (for __bar__).

## Installation

Just do ``configure --vgname=MyVG`` (replacing __MyVG__ with the actual name of your target volume group for home directories), and then ``make install``.

If your __systemd__ installation uses __sysconfdir__ other than ``/etc`` you can change it via ``--sysconfdir=/path/to/my/sys/conf/dir`` flag for ``configure``.

By default scripts are installed into ``/usr/local/bin``, use ``--bindir=`` option for ``configure`` to change it if necessary.

## Configuration

### Creating encrypted partition

First, lets create an appropriate logical volume inside of __MyVG__ volume group for __foo__ user (with id 1000):

    lvcreate -L 1G -n home_1000 MyVG

Now, let's encrypt it:

    cryptsetup -v --cipher aes-xts-plain64 --key-size 512 --hash sha512 --iter-time 2000 --use-urandom --verify-passphrase luksFormat /dev/mapper/MyVG-home_1000

_Please, note, that you have to use your user password as an encryption passphrase for this setup to work._

_Encryption parameters described here are sufficient for most users, although you can check man page and adjust them as needed._

It is time to create a filesystem on our newly encrypted and unlocked partition and set appropriate permissions for user:

    cryptsetup --type luks open /dev/mapper/MyVG-home_1000 home_1000
    mkfs.ext4 /dev/mapper/home_1000
    mount /dev/mapper/home_1000 /mnt
    chown foo:foo /mnt
    umount /mnt
    cryptsetup close home_1000

_You most likely want to backup you current content of the home folder. Additionally you can copy content of your home folder into that partition before umounting and closing it._

### Enabling pam service

To be able to automatically unencrypt your partition during login you have to save your login key somewhere for using it later inside of __systemd service__. In this case scripts are using ``keyctl`` userspace tool to store your password inside of [kernel key retention service](https://www.kernel.org/doc/Documentation/security/keys.txt).

For this purpose ``dm-crypt-home-password.sh`` is used. Add the following line to your ``/etc/pam.d/system-auth`` file right after __pam_unix.so__, so it should like something like this:

    auth  required  pam_unix.so  try_first_pass likeauth
    auth  optional  pam_exec.so  expose_authtok /usr/local/bin/dm-crypt-home-password.sh

_Please, remember to change path to ``dm-crypt-home-password.sh`` file if you have used ``--bindir`` configure option to change its location._

### Enabling systemd service

Last step is to enable systemd service responsible for actual mounting and unmounting of your encrypted storage.

    systemctl enable dm-crypt-home@1000.service

_1000 in this case is user ID._

### Additional mount options

There is a possibility to provide additional mounting options for your encrypted partitions. If you want to add some mounting options for all users create ``/etc/systemd/system/dm-crypt-home@.service.d/mount.conf`` or for single user ``/etc/systemd/system/dm-crypt-home@1000.service.d/mount.conf`` and put the following inside:

    [Service]
    Environment="mountOpts=-o rw,noatime,nodiratime"

_Substitute options as needed._

## Additional background information

Encryption keys are removed from keychain right after successfull mounting (just to be a bit more secure).

Unmounting script is repeatedly trying to unmount partition and kills running blocking processess until it succeeded. It is a bit "cruel" approach, but it works pretty well, because others methods were tried and failed, leaving LVM groups busy, preventing their deactivation. This is very important for the cases where you use LVM on top of RAID (as I currently do).

