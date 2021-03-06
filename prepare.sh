#!/bin/bash
# --- Use this to create a loopback device ---
# pacmd load-module module-null-sink sink_name=MySink
# pacmd update-sink-proplist MySink device.description=MySink
# pacmd load-module module-loopback sink=MySink
# pavucontrol to configure audio for apps

architecture=""
case $(uname -m) in
    i386 | i686)   architecture="386" ;;
    x86_64) architecture="amd64" ;;
    arm)    dpkg --print-architecture | grep -q "arm64" && architecture="arm64" || architecture="arm" ;;
esac

sudo apt install git cmake g++ libboost-all-dev libgmp-dev swig python3-numpy python3-mako python3-sphinx python3-lxml doxygen libfftw3-dev libsdl1.2-dev libgsl-dev libqwt-qt5-dev libqt5opengl5-dev python3-pyqt5 liblog4cpp5-dev libzmq3-dev python3-yaml python3-click python3-click-plugins python3-zmq python3-scipy python3-pip python3-gi-cairo python-is-python3 python3-jsonschema texlive-latex-base libqt5svg5-dev libunwind-dev libthrift-dev libspdlog-dev python3-pybind11 libclfft-dev libusb-dev pavucontrol libsndfile1-dev libusb-1.0-0-dev libportaudio-ocaml-dev libportaudio2 bison flex libavahi-common-dev libavahi-client-dev libzstd-dev python3-dev p7zip-full libtalloc-dev libpcsclite-dev libgnutls28-dev libmnl-dev libsctp-dev libpcap-dev liblttng-ctl-dev liblttng-ust-dev libfaac-dev libcppunit-dev libitpp-dev libfreetype-dev libglfw3-dev libfltk1.1-dev libsamplerate0-dev libfaad-dev clang-format libhidapi-dev libasound2-dev texlive-latex-base qttools5-dev-tools qttools5-dev pybind11-dev libssl-dev libtiff5-dev libi2c-dev g++ libsqlite3-dev freeglut3-dev cpputest qtmultimedia5-dev libvorbis-dev libogg-dev libqt5multimedia5-plugins checkinstall libqcustomplot-dev libqt5svg5-dev gettext libaio-dev screen libgl1-mesa-glx -y
if architecture="arm"
then
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
fi

pip3 install git+https://github.com/pyqtgraph/pyqtgraph@develop
pip3 install numpy scipy pygccxml bitstring scapy 

if architecture="amd64"
then
	wget https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB
	sudo apt-key add GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB
	echo "deb https://apt.repos.intel.com/oneapi all main" | sudo tee /etc/apt/sources.list.d/oneAPI.list
	sudo apt update
	sudo apt install opencl-headers intel-oneapi-runtime-opencl -y
	sudo apt install intel-oneapi-runtime-compilers intel-opencl-icd clinfo -y
fi

sudo pip3 install pybombs
pybombs auto-config
pybombs recipes add-default
pybombs prefix init ~/gnuradio

mkdir ~/gnuradio/bin
echo "mkdir builddir && cd builddir && cmake .. -DCMAKE_INSTALL_PREFIX=~/gnuradio && make -j `nproc` && make install && cd .. && rm -rf builddir" > ~/gnuradio/bin/build.sh
chmod +x ~/gnuradio/bin/build.sh
echo "source /home/$USER/gnuradio/setup_env.sh" >> ~/.bashrc
cd ~/gnuradio
source ./setup_env.sh
cd ~/gnuradio/src
mkdir hw
cd hw
git clone https://github.com/EttusResearch/uhd.git
cd ~/gnuradio/src/hw/uhd/host
mkdir builddir
cd builddir
if architecture="arm64" || architecture="arm"
then
	cmake .. -DNEON_SIMD_ENABLE=OFF -DCMAKE_INSTALL_PREFIX=/home/$USER/gnuradio
else
	cmake .. -DCMAKE_INSTALL_PREFIX=/home/$USER/gnuradio
fi
make -j`nproc`
sudo make install
sudo mkdir -p /home/$USER/gnuradio/share/uhd/images
sudo chown $USER:$USER -R /home/$USER/gnuradio
uhd_images_downloader
cd ..
rm -rf builddir
cd ..

cd ~/gnuradio/src

#echo "Updating repos"
#cd other
#for i in `ls -d */`;do echo $i && cd $i ; git pull && git submodule init && git submodule update ; cd ..;done
#cd hw 
#for i in `ls -d */`;do echo $i && cd $i ; git pull && git submodule init && git submodule update ; cd ..;done
#cd hw_modules
#for i in `ls -d */`;do echo $i && cd $i ; git pull && git submodule init && git submodule update ; cd ..;done
#cd gnuradio
#for i in `ls -d */`;do echo $i && cd $i ; git pull && git submodule init && git submodule update ; cd ..;done

mkdir -p ~/gnuradio/logs

echo "Building lib source"
mkdir -p ~/gnuradio/src/other
cd ~/gnuradio/src/other
git clone https://github.com/jgaeddert/liquid-dsp --recursive
git clone https://github.com/thestk/rtaudio --recursive
git clone https://github.com/gnuradio/volk --recursive
git clone https://github.com/greatscottgadgets/libbtbb --recursive
git clone https://github.com/osmocom/libosmo-dsp --recursive
git clone https://github.com/osmocom/osmo-ir77 --recursive
cd liquid-dsp && ./bootstrap.sh && ./configure --prefix=/home/$USER/gnuradio && make -j `nproc` && make install && make clean && cd ..
cd rtaudio && build.sh && cd ..
cd volk && build.sh && cd ..
volk_profile
cd libbtbb && build.sh && cd ..
cd libosmo-dsp && autoreconf -i && ./configure --prefix=/home/$USER/gnuradio && make -j `nproc` && make install && make clean && cd ..
cd osmo-ir77/codec && make && cp ir77_ambe_decode ~/gnuradio/bin/ && make clean && cd ../..

echo "Building hw source"
cd ~/gnuradio/src/hw
sudo chown -R $USER:root /lib/udev/rules.d
sudo chown -R $USER:root /etc/udev/rules.d

git clone https://github.com/rtlsdrblog/rtl-sdr-blog
git clone https://github.com/pothosware/SoapySDR --recursive
git clone https://github.com/myriadrf/LimeSuite.git --recursive
git clone https://github.com/analogdevicesinc/libiio --recursive
git clone https://github.com/analogdevicesinc/libad9361-iio --recursive
git clone https://github.com/airspy/airspyhf --recursive
git clone https://github.com/airspy/airspyone_host --recursive
git clone https://github.com/osmocom/libosmocore --recursive
git clone https://github.com/Nuand/bladeRF --recursive
git clone https://github.com/greatscottgadgets/hackrf --recursive

cd rtl-sdr-blog
mkdir builddir && cd builddir && cmake .. -DCMAKE_INSTALL_PREFIX=/home/$USER/gnuradio -DINSTALL_UDEV_RULES=ON && make -j`nproc` && sudo make install && cd .. && rm -rf builddir && cd ..

cd SoapySDR && build.sh && cd ..

cd LimeSuite && git checkout stable && mkdir builddir && cd builddir && cmake .. -DCMAKE_INSTALL_PREFIX=/home/$USER/gnuradio && make -j$(nproc) && make install && cd .. && rm -rf builddir 
cd udev-rules && sudo ./install.sh && cd ..
cd ~/gnuradio/src/hw

cd airspyhf && build.sh && cd ..
cd airspyone_host && build.sh && cd ..
cd libiio && mkdir build2 && cd build2 && cmake .. -DCMAKE_INSTALL_PREFIX=~/gnuradio && make -j `nproc` && make install && cd .. && rm -rf build2 && cd ..
cd libad9361-iio && build.sh && cd ..
cd bladeRF/host && build.sh && cd ../..
cd libosmocore && autoreconf -i && ./configure --prefix=/home/$USER/gnuradio && make -j `nproc` && make install && make clean && cd ..
cd hackrf/host && build.sh && cd ../..
if architecture="arm64"
then
	wget https://www.sdrplay.com/software/SDRplay_RSP_API-ARM64-3.07.1.run
	chmod +x SDRplay_RSP_API-ARM64-3.07.1.run
elif architecture="arm"
then
	wget https://www.sdrplay.com/software/SDRplay_RSP_API-ARM32-3.07.2.run
	chmod +x SDRplay_RSP_API-ARM32-3.07.2.run
elif architecture="386"
then
	wget https://www.sdrplay.com/software/SDRplay_RSP_API-Linux-3.07.1.run
	chmod +x SDRplay_RSP_API-Linux-3.07.1.run
fi

echo "Building soapy modules"
mkdir ~/gnuradio/src/hw_modules
cd ~/gnuradio/src/hw_modules
git clone https://github.com/pothosware/SoapyUHD --recursive
git clone https://github.com/pothosware/SoapyRTLSDR --recursive
git clone https://github.com/pothosware/SoapyAirspy --recursive
git clone https://github.com/pothosware/SoapyRemote --recursive
git clone https://github.com/pothosware/SoapyBladeRF --recursive
git clone https://github.com/pothosware/SoapyMultiSDR --recursive
git clone https://github.com/pothosware/SoapySDRPlay3 --recursive
cd SoapyUHD && build.sh && cd ..
cd SoapyRTLSDR && build.sh && cd ..
cd SoapyAirspy && build.sh && cd ..
cd SoapyRemote && build.sh && cd ..
cd SoapyBladeRF && build.sh && cd ..
cd SoapySDRPlay3 && build.sh && cd ..
cd SoapyMultiSDR && build.sh && cd ..
cd SoapyBladeRF && build.sh && cd ..

echo "Building gnuradio"
cd ~/gnuradio/src
git clone https://github.com/gnuradio/gnuradio --recursive
cd gnuradio
mkdir build && cd build && cmake -DCMAKE_BUILD_TYPE=Release -DPYTHON_EXECUTABLE=/usr/bin/python3 ../ -DCMAKE_INSTALL_PREFIX=/home/$USER/gnuradio/ && make -j `nproc` && make install && cd .. && rm -rf build

echo "Updating modules .."
mkdir ~/gnuradio/src/modules
cd ~/gnuradio/src/modules
git clone https://github.com/bkerler/gr-compress -b maint-3.10
git clone https://github.com/bkerler/gr-dect2 -b maint-3.10
git clone https://github.com/argilo/gr-flarm -b maint-3.10
git clone https://github.com/bkerler/gr-ham -b maint-3.10
git clone https://github.com/ghostop14/gr-xcorrelate
git clone https://github.com/bistromath/gr-air-modes -b gr3.9
git clone https://github.com/dl1ksv/gr-ax25
git clone https://github.com/drmpeg/gr-cessb
git clone https://github.com/duggabe/gr-control
git clone https://github.com/ghostop14/gr-correctiq
git clone https://github.com/argilo/gr-dsd
git clone https://github.com/argilo/gr-elster
git clone https://github.com/bastibl/gr-foo -b maint-3.9
git clone https://github.com/osmocom/gr-fosphor
git clone https://github.com/777arc/gr-hrpt
git clone https://github.com/bastibl/gr-ieee802-11 -b maint-3.9
git clone https://git.osmocom.org/gr-iqbal
git clone https://github.com/muaddib1984/gr-JAERO -b dev
git clone https://github.com/rpp0/gr-lora
git clone https://github.com/duggabe/gr-morse-code-gen
git clone https://github.com/argilo/gr-nrsc5
git clone https://github.com/bastibl/gr-keyfob -b maint-3.10
git clone https://github.com/BitBangingBytes/gr-smart_meters
git clone https://github.com/ant-uni-bremen/gr-symbolmapping
git clone https://gitlab.com/larryth/tetra-kit
git clone https://github.com/jdemel/XFDMSync
git clone https://github.com/ghostop14/gr-filerepeater
git clone https://github.com/bastibl/gr-rds -b maint-3.10
git clone https://github.com/bkerler/gr-m17 -b maint-3.10
git clone https://github.com/ghostop14/gr-mesa
git clone https://github.com/bkerler/gr-reveng -b maint-3.10
git clone https://github.com/bkerler/gr-lora_sdr -b maint-3.10
git clone https://github.com/bkerler/gr-radioteletype -b maint-3.10
git clone https://github.com/bkerler/gr-fhss_utils -b maint-3.10
git clone https://github.com/bkerler/darc -b maint-3.10
git clone https://github.com/bkerler/gr-adsb -b maint-3.10
git clone https://github.com/bkerler/gr-ais -b maint-3.10
git clone https://github.com/bkerler/gr-gfdm -b maint-3.10
git clone https://github.com/bkerler/gr-mixalot -b maint-3.10
git clone https://github.com/bkerler/gr-rftap -b maint-3.10
git clone https://github.com/MarcinWachowiak/gr-aoa
git clone https://github.com/ghostop14/gr-gpredict-doppler
git clone https://github.com/bkerler/gr-rtty -b maint-3.10
git clone https://github.com/ghostop14/gr-atsc2
git clone https://github.com/ghostop14/gr-grnet
git clone https://github.com/bkerler/gr-nfc -b maint-3.10
git clone https://github.com/daniestevez/gr-satellites
git clone https://github.com/bkerler/gr-gsm -b maint-3.10
git clone https://github.com/bkerler/gr-bruninga -b maint-3.10
git clone https://github.com/bkerler/gr-nordic -b maint-3.10
git clone https://github.com/ghostop14/gr-sql
git clone https://github.com/andrepuschmann/gr-cc11xx -b maint-3.10
git clone https://github.com/ghostop14/gr-guiextra
git clone https://github.com/bkerler/gr-ntsc-rc -b maint-3.10
git clone https://github.com/ghostop14/gr-symbolrate
git clone https://github.com/bkerler/gr-ccsds -b maint-3.10
git clone https://github.com/bkerler/gr-pager -b maint-3.10
git clone https://github.com/bkerler/gr-tempest -b maint-3.10
git clone https://github.com/drmpeg/gr-paint
git clone https://github.com/bkerler/gr-timing_utils -b maint-3.10
git clone https://github.com/bkerler/gr-dab -b maint-3.10
git clone https://github.com/bkerler/gr-inspector -b maint-3.10
git clone https://github.com/bkerler/gr-tpms -b maint-3.10
git clone https://github.com/bkerler/gr-pdu_utils -b maint-3.10
git clone https://github.com/bkerler/op25 -b maint-3.10
git clone https://github.com/muccc/gr-iridium --check
git clone https://github.com/dl1ksv/gr-display
git clone https://github.com/bkerler/gr-isdbt -b maint-3.10
git clone https://github.com/bkerler/gr-pcap -b maint-3.10
git clone https://github.com/bkerler/gr-pipe -b maint-3.10
git clone https://github.com/bkerler/scapy-radio -b maint-3.10
git clone https://github.com/bkerler/gr-dsmx-rc -b maint-3.10
git clone https://github.com/bkerler/gr-pocsag -b maint-3.10
git clone https://github.com/drmpeg/gr-dvbs2
git clone https://github.com/ghostop14/gr-lfast
git clone https://github.com/bkerler/gr-lacrosse -b maint-3.10
git clone https://github.com/bkerler/gr-ppm-rc -b maint-3.10
git clone https://github.com/bkerler/gr-FDC -b maint-3.10
git clone https://github.com/bkerler/gr-pylambda -b maint-3.10
git clone https://github.com/bastibl/gr-rstt -b maint-3.9
git clone https://github.com/bastibl/gr-sched -b maint-3.9
git clone https://github.com/duggabe/gr-morse-code-gen
git clone https://git.code.sf.net/u/bkerler/gr-acars.git
git clone https://github.com/bkerler/gr-ieee802-15-4 -b maint-3.10

#for i in `ls -d */`;do echo $i && cd $i ; git pull && git submodule init && git submodule update ; cd ..;done

echo "Building modules .."
for i in `ls -d */`;do echo $i && cd $i ; build.sh ; cd ..; done
cd ..

echo "Installing apps"
sudo apt install fldigi -y
pip3 install urh crcmod

mkdir ~/gnuradio/utils
cd ~/gnuradio/utils
git clone https://github.com/AlexandreRouma/SDRPlusPlus --recursive
cd SDRPlusPlus && mkdir build && cd build && cmake .. -DCMAKE_INSTALL_PREFIX=~/gnuradio && make -j `nproc` && sudo make install && cd ..

#git clone https://github.com/BatchDrake/SigDigger --recursive

if architecture="arm"
then
sudo swapoff /swapfile
sudo rm -rf /swapfile
fi
