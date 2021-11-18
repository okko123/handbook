## ffmpeg 编译安装
- 系统：Ubuntu 21.10
### 安装需要使用的依赖包
apt install -y libmfx1 libmfx-tools libva-dev libmfx-dev intel-media-va-driver-non-free vainfo

### 添加环境变量
cat >> ~/.bashrc <<EOF
export LIBVA_DRIVER_NAME=iHD
export PKG_CONFIG_PATH=/usr/lib/x86_64-linux-gnu/pkgconfig/
export LIBVA_DRIVERS_PATH=/usr/lib/x86_64-linux-gnu/dri/
export LD_LIBRARY_PATH=/opt/intel/mediasdk/lib/
EOF

### Intel Media SDK 编译
- 准备，通过官方[Intel-Media-SDK的release](https://github.com/Intel-Media-SDK/MediaSDK/releases)文档来知道分别是用libva和media-driver的哪个tag编译的。
  > ubuntu 21.10版本上，libva-dev包的版本为2.12，因此可以使用21.3.5版本的MSDK
sudo apt install -y git cmake pkg-config meson libdrm-dev automake libtool g++
tar xf MediaSDK-intel-mediasdk-21.3.5.tar.gz
cd MediaSDK-intel-mediasdk-21.3.5
mkdir build
cd build
cmake ../
make
make install

### FFMPEG编译
apt install -y yasm libvpx-dev libx264-dev libx265-dev
./configuration --arch=x86_64 --enable-vaapi --enable-libmfx --enable-libx265 --enable-libx264 --enable-gpl --prefix=/usr/local/ffmpeg
make
make install


### 验证
ffmpeg -codecs | grep qsv
---
- [Ubuntu20.04 ffmpeg添加 Intel核显QSV加速支持](https://zhuanlan.zhihu.com/p/372361709)