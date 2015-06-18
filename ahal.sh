#!/bin/bash
TOOLDIR="$(dirname `which $0`)"
source "$TOOLDIR/utility-functions.inc"

# Build droid-hal and other middleware
# To be executed under the Mer SDK


[ -z "$MERSDK" ] && ${TOOLDIR}/exec-mer.sh $0
[ -z "$MERSDK" ] && exit 0

source ~/.hadk.env

cd $ANDROID_ROOT

mchapter "7.1.1"

minfo "updating mer sdk"

sudo zypper ref -f ; sudo zypper -n dup

minfo "Bulding droid-hal-device packages"
mb2 -t $VENDOR-$DEVICE-armv7hl -s rpm/droid-hal-$DEVICE.spec build
mkdir -p $ANDROID_ROOT/droid-local-repo/$DEVICE
rm -f $ANDROID_ROOT/droid-local-repo/$DEVICE/droid-hal-*rpm
mv RPMS/*$DEVICE* $ANDROID_ROOT/droid-local-repo/$DEVICE
createrepo $ANDROID_ROOT/droid-local-repo/$DEVICE


minfo "Add local rpm to target"
sb2 -t $VENDOR-$DEVICE-armv7hl -R -m sdk-install \
ssu ar local-$DEVICE-hal file://$ANDROID_ROOT/droid-local-repo/$DEVICE
sb2 -t $VENDOR-$DEVICE-armv7hl -R -msdk-install ssu lr

minfo "Device specific config"
hadk
cd $ANDROID_ROOT
mb2 -t $VENDOR-$DEVICE-armv7hl -s hybris/droid-hal-configs/rpm/droid-hal-configs.spec build


minfo "Building packages (this will take some time)"

sb2 -t $VENDOR-$DEVICE-armv7hl -R -msdk-install ssu domain sales
sb2 -t $VENDOR-$DEVICE-armv7hl -R -msdk-install ssu dr sdk
sb2 -t $VENDOR-$DEVICE-armv7hl -R -msdk-install zypper ref
sb2 -t $VENDOR-$DEVICE-armv7hl -R -msdk-install zypper install droid-hal-$DEVICE-devel

mkdir -p $MER_ROOT/devel/mer-hybris
cd $MER_ROOT/devel/mer-hybris


function makepkg {
	unset PKG
	unset SPEC
	unset OTHER_RANDOM_NAME
	GITHUB_GROUP="mer-hybris"

	if [ "$1" ]; then
		PKG=$1
	fi
	if [ "$2" ]; then
		SPEC=$2
	else
		SPEC=$PKG
	fi
	if [ "$3" ]; then
		OTHER_RANDOM_NAME=$3
	fi
	if [ "$4" ]; then
		GITHUB_GROUP=$4
	fi
	
	cd $MER_ROOT/devel/mer-hybris
	git clone https://github.com/$GITHUB_GROUP/$PKG.git
	cd $PKG
	mb2 -s rpm/$SPEC.spec -t $VENDOR-$DEVICE-armv7hl build
	mkdir -p $ANDROID_ROOT/droid-local-repo/$DEVICE/$PKG/
	rm -f $ANDROID_ROOT/droid-local-repo/$DEVICE/$PKG/*.rpm
	mv RPMS/*.rpm $ANDROID_ROOT/droid-local-repo/$DEVICE/$PKG
	createrepo $ANDROID_ROOT/droid-local-repo/$DEVICE
	sb2 -t $VENDOR-$DEVICE-armv7hl -R -msdk-install zypper ref
}

makepkg "libhybris"
sb2 -t $VENDOR-$DEVICE-armv7hl -R -msdk-build zypper rm mesa-llvmpipe

makepkg "qt5-qpa-hwcomposer-plugin" "qt5-qpa-hwcomposer-plugin" "qt5-qpa-hwcomposer_plugin" "maikelwever"
#makepkg "qt5-qpa-hwcomposer-plugin"
makepkg "sensorfw" "sensorfw-qt5-hybris" "hybris-libsensorfw-gt5" "mer-packages"
makepkg "ngfd-plugin-droid-vibrator"
makepkg "qt5-feedback-haptics-droid-vibrator"
makepkg "pulseaudio-modules-droid"
makepkg "qtscenegraph-adaptation" "qtscenegraph-adaptation-droid"
makepkg "mce-plugin-libhybris" "mce-plugin-libhybris" "mce-plugin-libhybris" "nemomobile"

#makepkg "gst-jolla" "gst-jolla" "gst-jolla" "sailfishos"
#makepkg "nemo-gst-interfaces" "nemo-gst-interfaces" "nemo-gst-interfaces" "nemomobile"
#makepkg "droidmedia" "droidmedia" "droidmedia" "sailfishos"
#makepkg "gst-droid" "gst-droid" "gst-droid" "sailfishos"
#makepkg "gst-colorconv" "gst-colorconv" "gst-colorconv" "sailfishos"
#makepkg "gst-omx" "gst-omx" "gst-omx" "sailfishos"
#makepkg "gst-droidcamsrc" "gst-droidcamsrc" "gst-droidcamsrc" "sailfishos"
