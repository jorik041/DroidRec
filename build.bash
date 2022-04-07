#!/bin/bash

set -e

RUNDIR="$PWD"

dirprefix=""

if [ $# -ge 1 ]; then
    if [ $# -eq 2 ]; then
        if ( [ -e "$2/aapt2" ] && [ -e "$2/d8" ] && [ -e "$2/zipalign" ] && [ -e "$2/apksigner" ] ); then
            BUILD_TOOLS_DIR="$2";
            cd $BUILD_TOOLS_DIR;
            dirprefix="./";
        fi;
    fi;
    ANDROID_SDK_PLATFORM="$1"
fi;

echo "Preparing resources."

mkdir "$RUNDIR/gen"

"$dirprefix"aapt2 compile --dir "$RUNDIR/res" -o "$RUNDIR/resources.zip"
"$dirprefix"aapt2 link -I $ANDROID_SDK_PLATFORM/android.jar --manifest "$RUNDIR/AndroidManifest.xml" --java "$RUNDIR/gen" -o "$RUNDIR/res.apk" "$RUNDIR/resources.zip"
rm "$RUNDIR/resources.zip"

echo "Compiling sources."

mkdir "$RUNDIR/obj"

javac -source 1.8 -target 1.8 -bootclasspath $ANDROID_SDK_PLATFORM/android.jar -sourcepath java:gen $(find "$RUNDIR/src" "$RUNDIR/gen" -type f -name '*.java') -d "$RUNDIR/obj"

rm -rf gen

echo "Linking libraries."

"$dirprefix"d8 --release --classpath $ANDROID_SDK_PLATFORM/android.jar --output "$RUNDIR" $(find "$RUNDIR/obj" -type f)
rm -rf "$RUNDIR/obj"

echo "Packing application."

zip -j -u "$RUNDIR/res.apk" "$RUNDIR/classes.dex"

rm "$RUNDIR/classes.dex"
"$dirprefix"zipalign 4 "$RUNDIR/res.apk" "$RUNDIR/out-aligned.apk"
rm "$RUNDIR/res.apk"

if [ ! -f "$RUNDIR/signature.keystore" ]; then
  echo "Unsigned build complete."
  exit
fi

echo "Signing application."
"$dirprefix"apksigner sign --ks "$RUNDIR/signature.keystore" --out "$RUNDIR/app-build.apk" "$RUNDIR/out-aligned.apk"
rm "$RUNDIR/out-aligned.apk"

echo "Build complete."
