#!/bin/bash
TOOLDIR="$(dirname $0)"
source "$TOOLDIR/utility-functions.inc"

# Carries the sequence of steps under the Mer SDK.
# - Set up Ubuntu for building CyanogenMod.
#   I'm highly suspicious this step could just as well be done on Mer SDk itself but lets leave it for another time..
# - Set up Scratchbox2 for crosscompiling
# - Build the droid-hal, the middleware & friends, and finally,
# - Build the image!
[ -z "$MERSDK" ] && ${TOOLDIR}/exec-mer.sh $0
[ -z "$MERSDK" ] && exit 0

mchapter "4.3"
sudo zypper -n install android-tools createrepo zip || die

source ~/.hadk.env
UBUNTU_CHROOT="$MER_ROOT/sdks/ubuntu"
grep $(hostname) "$UBUNTU_CHROOT/etc/hosts"
if [ $? -ne 0 ]; then
	mkdir -p "$UBUNTU_CHROOT"

	minfo "setting up ubuntu chroot"
	mchapter "4.4.1"
	UBUNTU_CHROOT="$MER_ROOT/sdks/ubuntu"
	pushd "$MER_ROOT"
	TARBALL=ubuntu-trusty-android-rootfs.tar.bz2
	[ -f $TARBALL  ] || sudo curl -O http://img.merproject.org/images/mer-hybris/ubu/$TARBALL
	minfo "untaring ubuntu..."
	[ -f ${TARBALL}.untarred ] || sudo tar --numeric-owner -xjf $TARBALL -C "$UBUNTU_CHROOT" || die
	touch ${TARBALL}.untarred

	mchapter "4.4.2"
	grep $(hostname) "$UBUNTU_CHROOT/etc/hosts" || sudo sh -c "echo 127.0.0.2 $(hostname) >> \"$UBUNTU_CHROOT/etc/hosts\""

	popd

	cd ${TOOLDIR}
	# replace the shoddy ubu-chroot script
	sudo cp $TOOLDIR/ubu-chroot-fixed-cmd-mode `which ubu-chroot` || die
	sudo chmod +x `which ubu-chroot` || die
else
	echo "ubuntu chroot already set-up"
	UBUNTU_CHROOT="$MER_ROOT/sdks/ubuntu"
fi

minfo "diving into ubuntu chroot"
ubu-chroot -r "$MER_ROOT/sdks/ubuntu" `pwd`/task-ubu.sh || die
minfo "done ubuntu"

mchapter "6. sb2 setup"
./sb-setup.sh || die

if [ -z "$SKIP_HAL" ]; then
	./ahal.sh || die
fi

./build-img.sh || die

