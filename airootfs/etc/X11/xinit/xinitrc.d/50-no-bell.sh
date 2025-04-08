#!/bin/sh
# Disable X11 bell
# This script runs when X11 sessions start
# Part of the Arch Linux without beeps project

if [ -x /usr/bin/xset ]; then
    /usr/bin/xset -b
fi