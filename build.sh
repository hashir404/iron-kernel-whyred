#!/usr/bin/env bash
echo "Cloning dependencies"
git clone --depth=1 https://github.com/kdrag0n/proton-clang clang
git clone --depth=1 --single-branch -b whyred https://github.com/akira-vishal/AnyKernel3.git AnyKerne
echo "Done"
DEVICE=whyred
DEFCONFIG=whyred-newcam_defconfig
VERSION=X1
IMAGE=$(pwd)/out/arch/arm64/boot/Image.gz-dtb
TANGGAL=$(date +"%F-%S")
START=$(date +"%s")
KERNEL_DIR=$(pwd)
PATH="${PWD}/clang/bin:$PATH"
export KBUILD_COMPILER_STRING=$(${KERNEL_DIR}/clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
export ARCH=arm64
export SUBARCH=arm64
export LOCALVERSION="-${VERSION}"
export KBUILD_BUILD_HOST=droneci
export KBUILD_BUILD_USER="hashir"
# sticker plox
function sticker() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendSticker" \
        -d sticker="CAACAgUAAx0CVxrmOQABAuqhYHYLgi-2cn9jpggMD8VYBIEzQWgAAsQBAALU8vhUZa6bA1OeOtoeBA" \
        -d chat_id=$chat_id
}
# Send info plox channel
function sendinfo() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=html" \
        -d text="<b>• LazaruS Kernel •</b>%0ABuild started on <code>Drone CI</code>%0AFor device <b>Redmi Note 5 Pro</b> (whyred)%0Abranch <code>$(git rev-parse --abbrev-ref HEAD)</code>(master)%0AUnder commit <code>$(git log --pretty=format:'"%h : %s"' -1)</code>%0AUsing compiler: <code>${KBUILD_COMPILER_STRING}</code>%0AStarted on <code>$(date)</code>%0A<b>Build Status:</b>#STABLE"
}
# Push kernel to channel
function push() {
    cd AnyKernel
    ZIP=$(echo *.zip)
    curl -F document=@$ZIP "https://api.telegram.org/bot$token/sendDocument" \
        -F chat_id="$chat_id" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="Build took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s). | For <b>Redmi Note 5 Pro (whyred)</b> | <b>${KBUILD_COMPILER_STRING}</b>"
}
# Fin Error
function finerr() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=markdown" \
        -d text="Build throw an error(s)"
    exit 1
}
# Compile plox
function compile() {
		make O=out ARCH=arm64 ${DEFCONFIG}
		make -j$(nproc --all) O=out \
				ARCH=arm64 \
				CC=clang \
				CROSS_COMPILE=aarch64-linux-gnu- \
          CROSS_COMPILE_ARM32=arm-linux-gnueabi-

    if ! [ -a "$IMAGE" ]; then
        finerr
        exit 1
    fi
    cp out/arch/arm64/boot/Image.gz-dtb AnyKernel
}
# Zipping
function zipping() {
    cd AnyKernel || exit 1
    zip -r9 LazaruS-${VERSION}_${DEVICE}-OC-KERNEL-${TANGGAL}.zip *
    cd ..
}
sticker
sendinfo
compile
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
push
