#!/bin/bash
TOOLDIR="$(dirname $0)"
source "$TOOLDIR/utility-functions.inc"

# Build & hack a kickstart file and use it to make the final image
# To be executed under the Mer SDK



[ -z "$MERSDK" ] && ${TOOLDIR}/exec-mer.sh $0
[ -z "$MERSDK" ] && exit 0

source ~/.hadk.env

cd $ANDROID_ROOT

mchapter "8.2"
mkdir -p tmp
KSFL=$ANDROID_ROOT/tmp/Jolla-@RELEASE@-$DEVICE-@ARCH@.ks
HA_REPO="repo --name=adaptation0-$DEVICE-@RELEASE@"

sed -e \
"s|^$HA_REPO.*$|$HA_REPO --baseurl=file://$ANDROID_ROOT/droid-local-repo/$DEVICE|" \
$ANDROID_ROOT/installroot/usr/share/kickstarts/Jolla-@RELEASE@-$DEVICE-@ARCH@.ks \
> tmp/Jolla-@RELEASE@-$DEVICE-@ARCH@.ks

minfo "Adaptation"

minfo "extra packages"
# Not sure about them, yet... maybe include an external per-device file
PACKAGES_TO_ADD="sailfish-office jolla-calculator jolla-email jolla-notes jolla-clock jolla-mediaplayer jolla-calendar mce-plugin-libhybris strace jolla-devicelock-plugin-encsfa sailfish-version"

mchapter "Add adaptation and extra repos in image"

mchapter "8.3"
minfo "Info: create patterns"
[ -d hybris ] || mkdir -p hybris
./rpm/helpers/process_patterns.sh || die

cat $KSFL > ~/a.ks
mchapter "8.4"
minfo "create mic"
# always aim for the latest:
#RELEASE=1.0.8.19
#RELEASE=latest
# WARNING: EXTRA_NAME currently does not support '.' dots in it!
EXTRA_NAME=-${EXTRA_STRING}-$(date +%Y%m%d%H%M)
sudo mic create fs --arch armv7hl \
  --tokenmap=ARCH:armv7hl,RELEASE:$RELEASE,EXTRA_NAME:$EXTRA_NAME \
  --record-pkgs=name,url \
  --outdir=sfa-$DEVICE-$RELEASE$EXTRA_NAME \
  --pack-to=sfa-$DEVICE-$RELEASE$EXTRA_NAME.tar.bz2 \
  $KSFL 2>&1 | tee mic.log  || die
minfo "Info: copy image"
mkdir -p "$IMGDEST" || die
#cp -av sfa-${DEVICE}-${RELEASE}${EXTRA_NAME}/sailfishos-${DEVICE}-release-${RELEASE}${EXTRA_NAME}.zip "$IMGDEST"/ || die

#clean repos in target
minfo "Info: clean repos in target"

if repo_is_set "$MW_REPO"; then
  sb2 -t $VENDOR-$DEVICE-armv7hl -R -m sdk-install ssu rr mw-$DEVICE-hal
fi
if repo_is_set "$EXTRA_REPO"; then
  sb2 -t $VENDOR-$DEVICE-armv7hl -R -m sdk-install ssu rr extra-$DEVICE
fi
if repo_is_set "$DHD_REPO"; then
  sb2 -t $VENDOR-$DEVICE-armv7hl -R -m sdk-install ssu rr dhd-$DEVICE-hal
fi
sb2 -t $VENDOR-$DEVICE-armv7hl -R -m sdk-install ssu rr local-$DEVICE-hal
sb2 -t $VENDOR-$DEVICE-armv7hl -R -m sdk-install zypper ref -f
sb2 -t $VENDOR-$DEVICE-armv7hl -R -m sdk-install ssu lr

 
