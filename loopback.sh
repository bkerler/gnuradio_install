#!/bin/bash
pacmd load-module module-null-sink sink_name=VirtualCable
pacmd update-sink-proplist VirtualCable device.description=VirtualCable
pacmd load-module module-loopback sink=VirtualCable

