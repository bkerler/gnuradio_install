#!/bin/bash
# --- Use this to create a loopback device ---
# pacmd load-module module-null-sink sink_name=MySink
# pacmd update-sink-proplist MySink device.description=MySink
# pacmd load-module module-loopback sink=MySink
# pavucontrol to configure audio for apps
# modprobe snd-aloop
$MPATH = $PWD
architecture=""
case $(uname -m) in
    i386 | i686)   architecture="386" ;;
    x86_64) architecture="amd64" ;;
    arm)    dpkg --print-architecture | grep -q "arm64" && architecture="arm64" || architecture="arm" ;;
esac

if architecture="amd64"
then
    cd /tmp
	wget -O- https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB | gpg --dearmor | sudo tee /usr/share/keyrings/oneapi-archive-keyring.gpg > /dev/null
	echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main" | sudo tee /etc/apt/sources.list.d/oneAPI.list
	sudo apt update
	sudo apt install opencl-headers intel-oneapi-runtime-opencl-2024 -y
	sudo apt install intel-oneapi-runtime-compilers-2024 intel-opencl-icd clinfo -y
fi

echo "Installing os requirements..."
sudo apt install git cmake g++-12 libboost-all-dev libcairo2-dev castxml libgmp-dev libjs-mathjax doxygen libfftw3-dev libsdl1.2-dev libgsl-dev libqwt-qt5-dev libqt5opengl5-dev liblog4cpp5-dev libzmq3-dev texlive-latex-base libqt5svg5-dev libunwind-dev libthrift-dev libspdlog-dev libclfft-dev libusb-dev libusb-1.0-0-dev pavucontrol libsndfile1-dev libusb-1.0-0-dev libportaudio-ocaml-dev libportaudio2 bison flex libavahi-common-dev libavahi-client-dev libzstd-dev python3-dev p7zip-full libtalloc-dev libpcsclite-dev libgnutls28-dev libmnl-dev libsctp-dev libpcap-dev liblttng-ctl-dev liblttng-ust-dev libfaac-dev libcppunit-dev libitpp-dev libfreetype-dev libglfw3-dev libsamplerate0-dev libfaad-dev clang-format libhidapi-dev libasound2-dev texlive-latex-base qttools5-dev-tools qttools5-dev pybind11-dev libssl-dev libtiff5-dev libi2c-dev g++ libsqlite3-dev freeglut3-dev cpputest qtmultimedia5-dev libvorbis-dev libogg-dev libqt5multimedia5-plugins checkinstall libqcustomplot-dev libqt5svg5-dev gettext libaio-dev screen rapidjson-dev libgsm1-dev libcodec2-dev libqt5websockets5-dev libxml2-dev libcurl4-openssl-dev libcdk5-dev -y
# Not part of ubuntu 22.04 LTS
sudo apt install libfltk1.1-dev -y

sudo apt install dpdk dpdk-dev libconfig++-dev libmp3lame-dev libshout-dev liburing-dev libgirepository1.0-dev -y

echo "Compiling python 3.11"
mkdir -p /home/$USER/gnuradio
cd /home/$USER/gnuradio
pyenv install 3.11 -s
pyenv local 3.11

#if architecture="arm"
#then
#sudo fallocate -l 2G /swapfile
#sudo chmod 600 /swapfile
#sudo mkswap /swapfile
#sudo swapon /swapfile
#fi
echo "Setting up python environment"

pip3 install pybombs
pip3 install git+https://github.com/pyqtgraph/pyqtgraph@develop

echo "Setting up python requirements"
pip3 install numpy scipy pygccxml bitstring scapy loudify pandas pytest mako PyYAML pygobject==3.50.1 jsonschema pyqt5 click click-plugins pybind11==1.8 sphinx lxml zmq pycairo gevent pyudev pyroute2 pyusb

echo "Setting up pybombs"
pybombs auto-config
pybombs recipes add-defaults
pybombs prefix init ~/gnuradio

mkdir ~/gnuradio/bin
echo "mkdir builddir && cd builddir && cmake .. -DCMAKE_INSTALL_PREFIX=/home/$USER/gnuradio -DCMAKE_INSTALL_PREFIX=/home/$USER/gnuradio/ -DPYTHON_EXECUTABLE=`pyenv prefix`/bin/python3 && make -j `nproc` && make install && cd .. && rm -rf builddir" > ~/gnuradio/bin/build.sh
chmod +x ~/gnuradio/bin/build.sh
echo "source /home/$USER/gnuradio/setup_env.sh" >> ~/.bashrc
sudo chown -R $USER:root /lib/udev/rules.d
sudo chown -R $USER:root /etc/udev/rules.d
cd ~/gnuradio
source ./setup_env.sh
cd ~/gnuradio/src
mkdir hw
cd hw

echo "Buildung libuhd 4.4 with patches"
git clone https://github.com/EttusResearch/uhd.git
cd ~/gnuradio/src/hw/uhd
wget https://raw.githubusercontent.com/bkerler/antsdr_uhd/uhd_4.4/patches/uhd44_microphase.diff
patch -p1 < uhd44_microphase.diff
cd ~/gnuradio/src/hw/uhd/host

mkdir builddir
cd builddir
export PYENV_PREFIX=`pyenv prefix`
if architecture="arm64" || architecture="arm"
then
	cmake .. -DNEON_SIMD_ENABLE=OFF -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/home/$USER/gnuradio/
else
	cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/home/$USER/gnuradio/
fi
mkdir -p /home/$USER/gnuradio/lib
ln -s $PYENV_PREFIX/lib/libpython3.11.so.1.0 /home/$USER/gnuradio/lib/libpython3.11.so.1.0

make -j`nproc`
make install
mkdir -p /home/$USER/gnuradio/share/uhd/images
chown $USER:$USER -R /home/$USER/gnuradio
uhd_images_downloader
cd ..
cp utils/uhd-usrp.rules /etc/udev/rules.d/
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
git clone https://github.com/ttsou/turbofec
cd turbofec && autoreconf -i && ./configure --prefix=/home/$USER/gnuradio && make -j `nproc` && make install && make clean && cd ..
git clone https://github.com/d-bahr/CRCpp
cd CRCpp && build.sh && cd ..
git clone https://github.com/jgaeddert/liquid-dsp --recursive
wget http://www.music.mcgill.ca/~gary/rtaudio/release/rtaudio-5.2.0.tar.gz
tar xzvf rtaudio-5.2.0.tar.gz
rm rtaudio-5.2.0.tar.gz
git clone https://github.com/gnuradio/volk --recursive
git clone https://github.com/bkerler/libbtbb --recursive
git clone https://github.com/osmocom/libosmo-dsp --recursive
git clone https://github.com/osmocom/osmo-ir77 --recursive
cd liquid-dsp && ./bootstrap.sh && ./configure --prefix=/home/$USER/gnuradio && make -j `nproc` && make install && make clean && cd ..
cd rtaudio-5.2.0 && build.sh && cd ..
cd volk && build.sh && cd ..
volk_profile
cd libbtbb && build.sh && cd ..
cd libosmo-dsp && autoreconf -i && ./configure --prefix=/home/$USER/gnuradio && make -j `nproc` && make install && make clean && cd ..
cd osmo-ir77/codec && make && cp ir77_ambe_decode ~/gnuradio/bin/ && make clean && cd ../..

echo "Building hw source"
cd ~/gnuradio/src/hw

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
git clone https://github.com/cozycactus/librx888 --recursive
git clone https://github.com/rfnm/librfnm --recursive
git clone https://github.com/bkerler/gr-qs1r --recursive

cd rtl-sdr-blog
sudo cp rtl-sdr.rules /etc/udev/rules.d/
mkdir builddir && cd builddir && cmake .. -DCMAKE_INSTALL_PREFIX=/home/$USER/gnuradio -DINSTALL_UDEV_RULES=ON && make -j`nproc` && sudo make install && cd .. && rm -rf builddir && cd ..
echo 'blacklist dvb_usb_rtl28xxu' | sudo tee --append /etc/modprobe.d/blacklist-dvb_usb_rtl28xxu.conf

cd SoapySDR && build.sh && cd ..
cd librfnm && build.sh && cd ..

cd LimeSuite && git checkout stable
wget https://raw.githubusercontent.com/bkerler/gnuradio_install/main/limesuite.patch
git apply limesuite.patch
mkdir builddir && cd builddir && cmake .. -DCMAKE_INSTALL_PREFIX=/home/$USER/gnuradio && make -j$(nproc) && make install && cd .. && rm -rf builddir 
cd udev-rules && sudo ./install.sh && cd .. && cd ..

cd airspyhf
sudo cp tools/52-airspyhf.rules /etc/udev/rules.d/
build.sh && cd ..

cd airspyone_host
sudo cp airspy-tools/52-airspy.rules /etc/udev/rules.d/
build.sh && cd ..

cd libiio && git checkout b6028fd && build.sh && cd ..
cd libad9361-iio && build.sh && cd ..

cd bladeRF/host 
cp misc/udev/88-nuand-* /etc/udev/rules.d/
build.sh
cd ../..

cd libosmocore && autoreconf -i && ./configure --prefix=/home/$USER/gnuradio && make -j `nproc` && make install && make clean && cd ..

cd hackrf/host
sudo cp libhackrf/53-hackrf.rules /etc/udev/
build.sh && cd ../..

cd librx888 && build.sh && cd ..

if architecture="arm64"
then
	wget https://www.sdrplay.com/software/SDRplay_RSP_API-ARM64-3.07.1.run
	chmod +x SDRplay_RSP_API-ARM64-3.07.1.run
        ./SDRplay_RSP_API-ARM64-3.07.1.run --target out --noexec
elif architecture="arm"
then
	wget https://www.sdrplay.com/software/SDRplay_RSP_API-ARM32-3.07.2.run
	chmod +x SDRplay_RSP_API-ARM32-3.07.2.run
        ./SDRplay_RSP_API-ARM32-3.07.2.run --target out --noexec
elif architecture="amd64"
then
	wget https://www.sdrplay.com/software/SDRplay_RSP_API-Linux-3.07.1.run
 	chmod +x SDRplay_RSP_API-Linux-3.07.1.run
        ./SDRplay_RSP_API-Linux-3.07.1.run --target out --noexec
fi
cd out
cp 66-mirics.rules /etc/udev/rules.d/
ARCH=`uname -m`
VERS=3.07
INSTALLLIBDIR="/home/$USER/gnuradio/lib"
INSTALLINCDIR="/home/$USER/gnuradio/include"
INSTALLBINDIR="/home/$USER/gnuradio/bin"
cp -f inc/sdrplay_api*.h ${INSTALLINCDIR}/.
rm -f ${INSTALLLIBDIR}/libsdrplay_api.so.${VERS}
cp -f ${ARCH}/libsdrplay_api.so.${VERS} ${INSTALLLIBDIR}/.
rm -f ${INSTALLLIBDIR}/libsdrplay_api.so.${MAJVERS}
ln -s ${INSTALLLIBDIR}/libsdrplay_api.so.${VERS} ${INSTALLLIBDIR}/libsdrplay_api.so.${MAJVERS}
rm -f ${INSTALLLIBDIR}/libsdrplay_api.so
ln -s ${INSTALLLIBDIR}/libsdrplay_api.so.${MAJVERS} ${INSTALLLIBDIR}/libsdrplay_api.so
cd ..
rm -rf out

# spectran V6
git clone https://github.com/hb9fxq/libspectranstream
cd libspectranstream && build.sh && cd ..

echo "Building soapy modules"
mkdir ~/gnuradio/src/hw_modules
cd ~/gnuradio/src/hw_modules
git clone https://github.com/pothosware/SoapyUHD --recursive
git clone https://github.com/pothosware/SoapyRTLSDR --recursive
git clone https://github.com/pothosware/SoapyAirspy --recursive
git clone https://github.com/ast/SoapyAirspyHF --recursive
git clone https://github.com/pothosware/SoapyRemote --recursive
git clone https://github.com/pothosware/SoapyBladeRF --recursive
git clone https://github.com/pothosware/SoapyMultiSDR --recursive
git clone https://github.com/pothosware/SoapySDRPlay3 --recursive
git clone https://github.com/pothosware/SoapyPlutoSDR --recursive
git clone https://github.com/pothosware/SoapyHackRF --recursive
git clone https://github.com/hb9fxq/SoapySpectranV6 --recursive
git clone https://github.com/cozycactus/SoapyRX888 --recursive
git clone https://github.com/rfnm/soapy-rfnm --recursive

cd soapy-rfnm && build.sh && cd ..
cd SoapyUHD && build.sh && cd ..
cd SoapyRTLSDR && build.sh && cd ..
cd SoapyAirspy && build.sh && cd ..
cd SoapyRemote && build.sh && cd ..
cd SoapyBladeRF && build.sh && cd ..
#cd SoapySDRPlay3 && build.sh && cd ..
cd SoapyMultiSDR && build.sh && cd ..
cd SoapyBladeRF && build.sh && cd ..
cd SoapyPlutoSDR && build.sh && cd ..
cd SoapySpectranV6 && build.sh && cd ..
cd SoapyRX888 && build.sh && cd ..
cd SoapyHackRF && build.sh && cd ..

echo "Building gnuradio"
cd ~/gnuradio/src
git clone https://github.com/gnuradio/gnuradio --recursive
cd gnuradio
mkdir build && cd build && cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/home/$USER/gnuradio/ -DPYTHON_EXECUTABLE=$PYENV_PREFIX/bin/python3 -Dpybind11_DIR=`$PYENV_PREFIX/bin/pybind11-config --cmakedir` && make -j `nproc` && make install && cd .. && rm -rf build

echo "Updating modules .."
mkdir ~/gnuradio/src/modules
cd ~/gnuradio/src/modules

git clone https://github.com/ryanvolz/gr-hpsdr
cd gr-hpsdr
build.sh
cd ..

git clone https://github.com/hb9fxq/gr-aaronia_rtsa --recursive

# Maintainers might have 3.10 forks but do not accept PR
git clone https://github.com/bkerler/gr-iridium -b maint-3.10

# Sync in progress
git clone https://github.com/bkerler/gr-compress -b maint-3.10

# Repo updated, but PR not yet seen / accepted
git clone https://github.com/bkerler/gr-tempest -b maint-3.10

# Maintained by the authors / PR accepted or actively maintained
git clone https://github.com/osmocom/gr-osmosdr --recursive
git clone https://github.com/osmocom/gr-fosphor
git clone https://git.osmocom.org/gr-iqbal

git clone https://github.com/dl1ksv/gr-ax25
# Issue with spdlog, pr wasn't accepted
git clone https://github.com/bkerler/gr-airspy

git clone https://github.com/argilo/gr-flarm
git clone https://github.com/argilo/gr-dsd
git clone https://github.com/argilo/gr-elster
git clone https://github.com/argilo/gr-nrsc5
git clone https://github.com/argilo/gr-ham

git clone https://github.com/bastibl/gr-foo -b maint-3.10
#spdlog issue pr
git clone https://github.com/bkerler/gr-ieee802-11 -b maint-3.11
git clone https://github.com/bastibl/gr-ieee802-15-4 -b maint-3.10
git clone https://github.com/bastibl/gr-keyfob -b maint-3.10
git clone https://github.com/bastibl/gr-rds -b maint-3.10
git clone https://github.com/bastibl/gr-rstt -b maint-3.9
git clone https://github.com/bastibl/gr-sched -b maint-3.9

git clone https://github.com/ainfosec/gr-j2497 -b maint-3.10
git clone https://github.com/cpoore1/gr-clapper_plus -b maint-3.10
git clone https://github.com/cpoore1/gr-garage_door -b maint-3.10
git clone https://github.com/cpoore1/gr-tpms_poore -b maint-3.10
git clone https://github.com/cpoore1/gr-X10 -b maint-3.10
git clone https://github.com/cpoore1/gr-zwave_poore -b maint-3.10

git clone https://github.com/drmpeg/gr-paint
# Fix spdlog issue
git clone https://github.com/bkerler/gr-dvbs2 -b maint-3.11
git clone https://github.com/drmpeg/gr-cessb

git clone https://github.com/krono-i2/gr-spoof1090

git clone https://github.com/ghostop14/gr-filerepeater
git clone https://github.com/ghostop14/gr-mesa
git clone https://github.com/ghostop14/gr-gpredict-doppler
git clone https://github.com/ghostop14/gr-atsc2
git clone https://github.com/ghostop14/gr-grnet
git clone https://github.com/ghostop14/gr-sql
git clone https://github.com/ghostop14/gr-guiextra
git clone https://github.com/ghostop14/gr-symbolrate
git clone https://github.com/ghostop14/gr-xcorrelate
git clone https://github.com/ghostop14/gr-correctiq
git clone https://github.com/ghostop14/gr-lfast

git clone https://github.com/igorauad/gr-dvbs2rx --recursive

git clone https://github.com/jdemel/XFDMSync
git clone https://github.com/bkerler/gr-gfdm

git clone https://github.com/muaddib1984/gr-JAERO -b dev

git clone https://github.com/777arc/gr-hrpt
git clone https://github.com/andrepuschmann/gr-cc11xx
git clone https://github.com/ant-uni-bremen/gr-symbolmapping
git clone https://github.com/BitBangingBytes/gr-smart_meters
git clone https://github.com/daniestevez/gr-satellites
git clone https://github.com/bkerler/gr-display
git clone https://github.com/krakenrf/gr-krakensdr
git clone https://github.com/MarcinWachowiak/gr-aoa
git clone https://github.com/rpp0/gr-lora
git clone https://github.com/tapparelj/gr-lora_sdr
git clone https://github.com/bkerler/gr-inspector -b maint-3.10
git clone https://github.com/bkerler/m17-cxx-demod
git clone https://github.com/redwiretechnologies/gr-enocean
git clone https://github.com/pavelyazev/gr-dect2
git clone https://github.com/jacobagilbert/gr-sigmf_utils
git clone https://github.com/unsynchronized/gr-mixalot

git clone https://github.com/bkerler/gr-pdu_utils -b maint-3.10
git clone https://github.com/bkerler/gr-sandia_utils -b maint-3.10
git clone https://github.com/bkerler/gr-timing_utils -b maint-3.10
git clone https://github.com/bkerler/gr-fhss_utils -b maint-3.10

# Special version
git clone https://github.com/bkerler/gr-reveng

# Not fully ported to gr-3.10
git clone https://github.com/bkerler/gr-air-modes -b maint-3.10

# PR not yet accepted / no response or no PR
git clone https://github.com/bkerler/gr-HighDataRate_Modem
git clone https://github.com/bkerler/gr-nordic -b maint-3.10
git clone https://github.com/bkerler/gr-adsb -b maint-3.10
git clone https://github.com/bkerler/gr-ntsc-rc -b maint-3.10
git clone https://github.com/bkerler/gr-bluetooth -b maint-3.10
git clone https://github.com/bkerler/gr-nfc -b maint-3.10
git clone https://github.com/bkerler/gr-radioteletype -b maint-3.10
git clone https://github.com/bkerler/gr-ais -b maint-3.10
git clone https://github.com/bkerler/gr-rftap -b maint-3.10
git clone https://github.com/bkerler/gr-rtty -b maint-3.10
git clone https://github.com/bkerler/gr-bruninga -b maint-3.10
git clone https://github.com/bkerler/gr-ccsds -b testing
git clone https://github.com/bkerler/gr-pager -b maint-3.10
git clone https://github.com/bkerler/gr-dab -b maint-3.10
git clone https://github.com/bkerler/gr-tpms -b maint-3.10
git clone https://github.com/bkerler/gr-isdbt -b maint-3.10
git clone https://github.com/bkerler/gr-pcap -b maint-3.10
git clone https://github.com/bkerler/gr-pipe -b maint-3.10
git clone https://github.com/bkerler/gr-dsmx-rc -b maint-3.10
git clone https://github.com/bkerler/gr-lacrosse -b maint-3.10
git clone https://github.com/bkerler/gr-ppm-rc -b maint-3.10
git clone https://github.com/bkerler/gr-FDC -b maint-3.10
git clone https://github.com/bkerler/gr-pylambda -b maint-3.10
git clone https://github.com/bkerler/gr-limesdr -b maint-3.10
# Issue with libsgp4 (librespacefoundation)
git clone https://gitlab.com/bkerler/gr-leo
#for i in `ls -d */`;do echo $i && cd $i ; git pull && git submodule init && git submodule update ; cd ..;done

git clone https://github.com/muaddib1984/gr-pyais_json

cd gr-pdu_utils && build.sh && cd ..
cd gr-sandia_utils && build.sh && cd ..
cd gr-timing_utils && build.sh && cd ..
cd gr-fhss_utils && build.sh && cd ..

echo "Building modules .."
for i in `ls -d */`;do echo ${i%%/} && cd ${i%%/} ; build.sh ; cd ..; done

git clone https://github.com/bkerler/gr-gsm -b maint-3.10_with_multiarfcn
cd gr-gsm && build.sh && cd ..

git clone https://git.code.sf.net/u/bkerler/gr-acars.git
cd gr-acars/3.10ng/ && build.sh && cd ../..

#git clone https://github.com/llamaonaskateboard/op25
#cd op25/op25
#cd gr-op25_repeater && build.sh && cd ..
#cd gr-op25 && build.sh && cd ..
#cd ../../

git clone https://github.com/bkerler/darc -b maint-3.10
cd darc/src/gr-darc
build.sh
cd ../../../

git clone https://github.com/bkerler/scapy-radio -b maint-3.10
cd scapy-radio/gnuradio
cd gr-bt4le && build.sh && cd ..
cd gr-scapy_radio && build.sh && cd ..
cd gr-zigbee && build.sh && cd ..
cd gr-Zwave && build.sh && cd ..
cd ../..

git clone https://github.com/zeetwii/mockingbird
cd mockingbird/gr-adsb && build.sh && cd ../..

git clone https://github.com/bkerler/gr-m17 -b maint-3.10
cd gr-m17 && build.sh && cd ..

git clone https://github.com/bkerler/dji_droneid -b gr-droneid-update-3.10
cd dji_droneid/gnuradio/gr-droneid && build.sh && cd ../../..

git clone https://github.com/bkerler/ais-simulator -b maint-3.10
cd ais-simulator/gr-ais_simulator && build.sh && cd ../..
git clone https://github.com/bkerler/ais -b maint-3.10
cd ais/gr-aistx && build.sh && cd ../..

#if architecture="arm"
#then
#sudo swapoff /swapfile
#sudo rm -rf /swapfile
#fi
sudo sysctl -w net.core.wmem_max=24862979

sudo chown -R root:root /lib/udev/rules.d
sudo chown -R root:root /etc/udev/rules.d

# Optional for LiveDVD + Systemback
while true; do
read -p "Do you want to install LiveDVD tools? (yes/no) " yn
case $yn in 
	yes ) cd /tmp && wget https://revskills.de/dist/setup && chmod +x setup && ./setup && sudo apt install xfce4-xkb-plugin
		break;;
	no ) exit;;
	* ) echo invalid response;;
esac
done
