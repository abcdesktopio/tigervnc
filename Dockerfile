
# Default release is 18.04
ARG BASE_IMAGE_RELEASE=20.04
# Default base image 
ARG BASE_IMAGE=ubuntu:20.04

# use FROM BASE_IMAGE
# define FROM befire use ENV command
FROM ${BASE_IMAGE}

# define ARG 
ARG BASE_IMAGE_RELEASE
ARG BASE_IMAGE

# set non interactive
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
# enable source list
RUN sed -i '/deb-src/s/^# //' /etc/apt/sources.list 
# run update
RUN apt update
# install dev, dep and sources
RUN apt-get install -y --no-install-recommends ca-certificates fakeroot devscripts devscripts binutils wget
RUN apt-get build-dep -y tigervnc 

# download files 
RUN mkdir /build
WORKDIR /build
RUN wget https://github.com/TigerVNC/tigervnc/archive/v1.12.0/tigervnc-1.12.0.tar.gz
RUN wget https://www.x.org/pub/individual/xserver/xorg-server-1.20.7.tar.bz2
RUN wget https://www.linuxfromscratch.org/patches/blfs/svn/tigervnc-1.12.0-configuration_fixes-1.patch

# extract files
RUN tar -xvf tigervnc-1.12.0.tar.gz

# apply patch
WORKDIR /build/tigervnc-1.12.0 
RUN patch -Np1 -i ../tigervnc-1.12.0-configuration_fixes-1.patch

# download xserver
RUN tar -xf ../xorg-server-1.20.7.tar.bz2 --strip-components=1 -C unix/xserver
RUN cd unix/xserver && patch -Np1 -i ../xserver120.patch 

#make viewver
RUN cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX=/usr  -DCMAKE_BUILD_TYPE=Release -DINSTALL_SYSTEMD_UNITS=OFF -Wno-dev . && make

# make server
WORKDIR /build/tigervnc-1.12.0/unix/xserver
RUN autoreconf -fiv 
RUN CPPFLAGS="-I/usr/include/drm"       \
    ./configure $XORG_CONFIG            \
      --disable-xwayland    --disable-dri        --disable-dmx         \
      --disable-xorg        --disable-xnest      --enable-xvfb        \
      --disable-xwin        --disable-xephyr     --disable-kdrive      \
      --disable-devel-docs  --disable-config-hal --disable-config-udev \
      --disable-unit-tests  --disable-selective-werror                 \
      --disable-static      --enable-dri3                              \
      --without-dtrace      --enable-dri2        --enable-glx          \
      --with-pic
RUN  make
RUN  make install  
