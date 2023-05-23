#!/bin/bash
# --- Use this to create a loopback device ---
# pacmd load-module module-null-sink sink_name=MySink
# pacmd update-sink-proplist MySink device.description=MySink
# pacmd load-module module-loopback sink=MySink
# pavucontrol to configure audio for apps
# modprobe snd-aloop

architecture=""
case $(uname -m) in
    i386 | i686)   architecture="386" ;;
    x86_64) architecture="amd64" ;;
    arm)    dpkg --print-architecture | grep -q "arm64" && architecture="arm64" || architecture="arm" ;;
esac

cd ~/gnuradio
source ./setup_env.sh

echo "Downloading scripts / flowgraphs"
mkdir ~/gnuradio/flowgraphs
cd ~/gnuradio/flowgraphs
git clone https://github.com/bkerler/ham2mon -b maint-3.10
git clone https://github.com/bkerler/gr-pocsag -b maint-3.10
git clone https://github.com/bkerler/gnuradio_flowgraphs
git clone https://github.com/muaddib1984/wavetrap
git clone https://github.com/duggabe/gr-control
git clone https://github.com/duggabe/gr-morse-code-gen
git clone https://github.com/handiko/gr-APRS
git clone https://github.com/handiko/gr-HDLC-AFSK
git clone https://github.com/argilo/sdr-examples
git clone https://github.com/jhonnybonny/CleverJAM -b maint-3.10
git clone https://github.com/RUB-SysSec/DroneSecurity
git clone https://github.com/henningM1r/gr_DCF77_Receiver

echo "Installing apps"
sudo apt install fldigi qsstv inspectrum -y
pip3 install urh crcmod
mkdir ~/gnuradio/utils
cd ~/gnuradio/utils

git clone https://github.com/muaddib1984/stillsuit
git clone https://github.com/muaddib1984/arrakis
git clone https://github.com/szpajder/dumpvdl2
git clone https://github.com/ggerganov/whisper.cpp
cd whisper.cpp
./build.sh && bash ./models/download-ggml-model.sh base
make -j
cd ..

git clone https://gitlab.com/larryth/tetra-kit
cd tetra-kit && ./build.sh && cd ..

git clone https://github.com/Oros42/IMSI-catcher
git clone https://github.com/EliasOenal/multimon-ng
cd multimon-ng
mkdir build
cd build
qmake ../multimon-ng.pro PREFIX=/home/$USER/gnuradio
make
make install
cd ../..

sudo snap install sdrangel

git clone https://github.com/Mictronics/multi-sdr-gps-sim
cd multi-sdr-gps-sim
make all HACKRFSDR=yes PLUTOSDR=yes
cp gps-sim ~/gnuradio/bin/
cd ..

git clone https://github.com/osqzss/gps-sdr-sim
cd gps-sdr-sim
gcc gpssim.c -lm -O3 -o gps-sdr-sim
cp gpssim.c ~/gnuradio/bin
cd ..

git clone https://github.com/AlexandreRouma/SDRPlusPlus
cd SDRPlusPlus && mkdir build && cd build && cmake .. -DCMAKE_INSTALL_PREFIX=~/gnuradio && make -j `nproc` && sudo make install && cd ../..

git clone https://github.com/gqrx-sdr/gqrx
cd gqrx && build.sh && cd ..

mkdir SigDigger
cd SigDigger
git clone https://github.com/BatchDrake/sigutils --recursive
cd sigutils && build.sh && cd ..
git clone https://github.com/BatchDrake/suscan --recursive
cd suscan && build.sh && cd ..
git clone https://github.com/BatchDrake/SuWidgets
cd SuWidgets
qmake SuWidgets.pro PREFIX=/home/$USER/gnuradio
make -j 4
sudo make install
cd ..
git clone https://github.com/BatchDrake/SigDigger --recursive
cd SigDigger
qmake SigDigger.pro PREFIX=/home/$USER/gnuradio
make -j 4
sudo make install
cd ..

wget https://github.com/DSheirer/sdrtrunk/releases/download/v0.5.0/sdr-trunk-linux-x86_64-v0.5.0.zip
7z x sdr-trunk-linux-x86_64-v0.5.0.zip
rm sdr-trunk-linux-x86_64-v0.5.0.zip

git clone https://github.com/rxseger/rx_tools
cd rx_tools
build.sh
cd ..

git clone https://github.com/charlie-foxtrot/RTLSDR-Airband
cd RTLSDR-Airband/src
build.sh
cd ../..

git clone https://github.com/merbanan/rtl_433
cd rtl_433
build.sh
cd ..

git clone https://github.com/mikeryan/ice9-bluetooth-sniffer
cd ice9-bluetooth-sniffer
mkdir builddir
cd builddir
cmake .. -DCMAKE_INSTALL_PREFIX=~/gnuradio -DHACKRF_INCLUDE_DIR=~/gnuradio/include -DLIQUID_INCLUDE_DIR=~/gnuradio/include
make
make install
cd ..
rm -rf builddir
cd ..

cd ~/Downloads
wget --mirror --convert-links --html-extension --wait=2 -o log https://pysdr.org

