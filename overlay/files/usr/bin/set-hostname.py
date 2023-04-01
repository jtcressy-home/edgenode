#!/usr/bin/env python3
import os
import re
import subprocess


def slugify(s):
    s = s.lower().strip()
    s = re.sub(r'[^\w\s-]', '', s)
    s = re.sub(r'[\s_-]+', '-', s)
    s = re.sub(r'^-+|-+$', '', s)
    return s

def rpiserial():
    try:
        with open('/proc/cpuinfo', 'r') as f:
            for line in f:
                if line[0:6]=='Serial':
                    return line.split(':')[-1].strip()[-8:-1]
    except:
        return "ERROR000000000"

def rpimfg():
    return "raspberrypi"

def dmiserial():
    return slugify(subprocess.check_output("dmidecode -s system-serial-number", shell=True).decode("utf-8").replace(" ", ""))

def dmimfg():
    return slugify(subprocess.check_output("dmidecode -s system-manufacturer", shell=True).decode("utf-8"))

if os.path.exists("/sys/firmware/dmi"):
    mfg = dmimfg()
    serial = dmiserial()
elif os.path.exists("/sys/firmware/fdt"):
    mfg = rpimfg()
    serial = rpiserial()
else:
    mfg = "unknown"
    serial = "0"

with open('/proc/cmdline', 'r') as f:
    cmdline = f.read()
if "CDLABEL" in cmdline or "rd.cos.disable" in cmdline or "edgenode.livecd" in cmdline:
    suffix = '-livecd'
else:
    suffix = ''

hostname = f"{mfg}-{serial}{suffix}"[:32]
print(f"setting hostname to {hostname}")
os.system(f"hostnamectl set-hostname {hostname}")
exit(0)