#!/bin/bash

KERNEL_DIR=$PWD
# check target
# (note) MULTI and COM use same defconfig
BUILD_DEFCONFIG=semc_urushi_defconfig
BIN_DIR=out/$BUILD_TARGET/bin
OBJ_DIR=out/$BUILD_TARGET/obj
mkdir -p $BIN_DIR
mkdir -p $OBJ_DIR

# boot splash header
if [ -f ./drivers/video/samsung/logo_rgb24_user.h ]; then
  export USER_BOOT_SPLASH=y
fi

# check and get compiler
. cross_compile

# set build env
export ARCH=arm
export CROSS_COMPILE=$BUILD_CROSS_COMPILE
#export LOCALVERSION="-$BUILD_LOCALVERSION"

echo "=====> BUILD START $BUILD_KERNELVERSION-$BUILD_LOCALVERSION"

if [ ! -n "$1" ]; then
  echo ""
  read -p "select build? [(a)ll/(u)pdate default:update] " BUILD_SELECT
else
  BUILD_SELECT=$1
fi


# make start
if [ "$BUILD_SELECT" = 'all' -o "$BUILD_SELECT" = 'a' ]; then
  echo ""
  echo "=====> cleaning"
  rm -rf out
  mkdir -p $BIN_DIR
  mkdir -p $OBJ_DIR
  cp -f ./arch/arm/configs/$BUILD_DEFCONFIG $OBJ_DIR/.config
  make -C $PWD O=$OBJ_DIR oldconfig || exit -1
fi


echo ""
echo "=====> build start"
if [ -e make.log ]; then
mv make.log make_old.log
fi
nice -n 10 make O=$OBJ_DIR -j12 2>&1 | tee make.log


# check compile error
COMPILE_ERROR=`grep 'error:' ./make.log`
if [ "$COMPILE_ERROR" ]; then
  echo ""
  echo "=====> ERROR"
  grep 'error:' ./make.log
  exit -1
fi

if [ ! -e $OUTPUT_DIR ]; then
  mkdir -p $OUTPUT_DIR
fi

echo ""
echo "=====> CREATE RELEASE IMAGE"
# clean release dir
if [ `find $BIN_DIR -type f | wc -l` -gt 0 ]; then
  rm $BIN_DIR/*
fi

# copy zImage
cp $OBJ_DIR/arch/arm/boot/zImage $BIN_DIR/zImage
cp $OBJ_DIR/arch/arm/boot/zImage ./out/
#echo "  $BIN_DIR/zImage"
echo "  out/zImage"
#cleanup
rm $KERNEL_DIR/$BIN_DIR/zImage

cd $KERNEL_DIR
echo ""
echo "=====> BUILD COMPLETE $BUILD_KERNELVERSION-$BUILD_LOCALVERSION"
exit 0
