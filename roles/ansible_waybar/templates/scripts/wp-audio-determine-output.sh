#!/usr/bin/env bash
devicename=$(pw-metadata -n default 0 default.audio.sink | sed -n 's/.*"name":"\([^"]*\)".*/\1/p')
if [ $devicename == "alsa_output.usb-Focusrite_Scarlett_4i4_4th_Gen_S43VUTE4709AC2-00.analog-surround-21" ] ; then
  echo "Speaker"
elif [ $devicename == "alsa_output.usb-Kingston_HyperX_Virtual_Surround_Sound_00000000-00.analog-stereo" ] ; then 
  echo "Headphones"
fi
