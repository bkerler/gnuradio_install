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
git clone https://github.com/argilo/sdr-examples

git clone https://gitlab.com/crankylinuxuser/meshtastic_sdr
git clone https://github.com/bkerler/ham2mon -b maint-3.10
git clone https://github.com/bkerler/gr-pocsag -b maint-3.10
git clone https://github.com/bkerler/gnuradio_flowgraphs

git clone https://github.com/duggabe/gr-control
git clone https://github.com/duggabe/gr-morse-code-gen

git clone https://github.com/ereuter/PyEOT

git clone https://github.com/handiko/gr-APRS
git clone https://github.com/handiko/gr-HDLC-AFSK

git clone https://github.com/jhonnybonny/CleverJAM -b maint-3.10

git clone https://github.com/RUB-SysSec/DroneSecurity

git clone https://github.com/nootedandrooted/rtl-sdr-close-call-monitor

git clone https://github.com/henningM1r/gr_DCF77_Receiver
git clone https://github.com/henningM1r/gr_MSF60_Receiver
git clone https://github.com/henningM1r/gr_UK-AMDS_Receiver

git clone https://github.com/muaddib1984/stillsuit
git clone https://github.com/muaddib1984/gr-webspectrum
git clone https://github.com/muaddib1984/wavetrap
git clone https://github.com/muaddib1984/stillsuit
git clone https://github.com/muaddib1984/arrakis

wget https://kuenzi.dev/assets/files/sniff_NFC.grc
git clone https://github.com/bkerler/GnuRadio-Wireshark-Example
git clone https://github.com/SanchezCris/SDR-Automatic-Speech-Recognition

echo "Installing apps"
sudo apt install fldigi qsstv inspectrum -y
# Needed for urh
pip3 install crcmod
mkdir ~/gnuradio/utils
cd ~/gnuradio/utils

git clone https://github.com/SatDump/SatDump
git clone https://github.com/jvde-github/AIS-catcher
git clone https://github.com/szpajder/dumpvdl2
git clone https://github.com/ggerganov/whisper.cpp
cd whisper.cpp
bash ./models/download-ggml-model.sh base
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

git clone https://github.com/potto216/rf-analysis

git clone https://github.com/josevcm/nfc-laboratory

git clone https://github.com/AlexandreRouma/SDRPlusPlus
cd SDRPlusPlus && mkdir build && cd build && cmake .. -DCMAKE_INSTALL_PREFIX=~/gnuradio -DOPT_BUILD_LIMESDR_SOURCE=ON -DOPT_BUILD_M17_DECODER=ON -DOPT_BUILD_METEOR_DEMODULATOR=ON -DOPT_BUILD_NEW_PORTAUDIO_SINK=ON -DOPT_BUILD_PAGER_DECODER=ON -DOPT_BUILD_RECORDER=ON -DOPT_BUILD_SOAPY_SOURCE=ON && make -j `nproc` && sudo make install && cd ../..

git clone https://github.com/gqrx-sdr/gqrx
cd gqrx && build.sh && cd ..

mkdir SigDigger
cd SigDigger
git clone https://github.com/BatchDrake/sigutils -b develop --recursive
git clone https://github.com/BatchDrake/suscan -b develop --recursive
git clone https://github.com/BatchDrake/SuWidgets -b develop --recursive
git clone https://github.com/BatchDrake/SigDigger -b develop --recursive
cd sigutils && build.sh && cd ..
cd suscan && build.sh && cd ..
cd SuWidgets
qmake SuWidgets.pro PREFIX=/home/$USER/gnuradio
make -j 4
make install
cd ..
cd SigDigger
echo "INCLUDEPATH += /home/$USER/gnuradio/include/SuWidgets" >> SigDigger.pro
qmake SigDigger.pro PREFIX=/home/$USER/gnuradio
make -j 4
make install
cd ../..

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

git clone https://github.com/bkerler/ice9-bluetooth-sniffer -b working_uhd_and_soapy_new
cd ice9-bluetooth-sniffer
mkdir builddir
cd builddir
cmake .. -DCMAKE_INSTALL_PREFIX=~/gnuradio
make
make install
cd ..
rm -rf builddir
cd ..

cd ~/Downloads
wget --mirror --convert-links --html-extension --wait=2 -o log https://pysdr.org

