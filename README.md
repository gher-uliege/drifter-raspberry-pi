## Installation

### Operating System


Installing raspberry pi Imager (https://www.raspberrypi.com/software/) in Ubuntu:

```bash
sudo dpkg -i imager_1.7.2_amd64.deb
rpi-imager
```

And install Rapberry Pi OS Lite (64-bit) onto the SD coard. It is important (for julia) to select the 64-bit version.
In the advanced settings (Use `CTRL + SHIFT + X`), one should enable SSH, set a SSH password, configure WiFi by setting the WiFi network name (ESSID) and password.


## First step

Determine the Raspberry pi IP address and connect via SSH.

These are the basic shell commands:

```
ls
cd directory_name
rm file_name
cat /proc/cpuinfo
wget some_url
top
```


### Julia


Go to https://julialang.org/downloads/, download and install julia for aarch64.

https://julialang-s3.julialang.org/bin/linux/aarch64/1.8/julia-1.8.0-linux-aarch64.tar.gz

```julia
using Pkg
Pkg.add("LibSerialPort")
```

Install other software: pigpiod is a daemon for controling the general purpose I/O pins (GPIO)

```bash
sudo apt-get install minicom p7zip-full git emacs-nox pigpiod
sudo timedatectl set-timezone UTC
sudo systemctl enable pigpiod
sudo systemctl start pigpiod
```



## Warm-up: On-board led blinking


Start Julia as root

```bash
sudo julia
```

Enter the following Julia commands:

```julia
write("/sys/class/leds/led0/trigger","none")
write("/sys/class/leds/led0/brightness","1")
write("/sys/class/leds/led0/brightness","0")
```

Blinking leds:

```julia
filename = "/sys/class/leds/led0/brightness";

while true;
   write(filename,"0");
   sleep(0.5);
   write(filename,"1");
   sleep(0.5);
end
```

Idea: What about to implement [Morse code](https://en.wikipedia.org/wiki/Morse_code) ?



## GSM Modem

We will need the SIM card in its standard card size (25 mm by 15 mm).

* Place the SIM card in the WaveShare Hat (gently, very gently)
* Connect the GNSS (GPS) and GSM atennas to the Modem
* Connect the WaveShare Model with the Rasbperry Pi and fix with srews
* Power on the Rasbperry Pi
* Power on the WaveShare Hat

The Modem uses a series of so called [AT commands](https://en.wikipedia.org/wiki/Hayes_command_set).
All commands start with `AT` (meaning 'attention').
All commands end with the characters `\r\n`. The basic commands used here are the following:


| Command  | Description  | Return value |
|---|---|---|
| AT  | Test Modem  |  OK |
| AT+CPIN? | | |
| AT+CPIN="1234" | Unlook SIM using pin 1234 | |
| AT+CREG? | Network registration status | |
| ATD0032XXXXXXXXX; | call a phone number 0032XXXXXXXXX (replacing all X by numbers) | |


## Minicom first tests

```bash
sudo minicom -D /dev/ttyS0
```

- These commands should not return ERROR:
AT

AT+CPIN="XXXX"

AT+CREG?

- Command to call a phone number
ATD0032XXXXXXXXX;

Some CREG info: https://web.archive.org/web/20230121160033/https://docs.eseye.com/Content/ELS61/ATCommands/ELS61CREG.htm

# Tests in Julia

Open the serial port:

``` julia
using LibSerialPort
sp = LibSerialPort.open("/dev/ttyS0", 115200)
```

Execute a command:
``` julia
write(sp, "AT\r\n")
```

Read its output
``` julia
if bytesavailable(sp) > 0; println(String(read(sp))); end
# output
# OK
```


### SMS

| Command  | Description  | Return value |
|---|---|---|
| AT+CMGF=1  | Set the format of messages to Text mode  |   |
| AT+CSCA="some number"  |   |   |
| AT+CMGS="phone_number" |   |   |


### Global Navigation Satellite System (GNSS)

Examples of GNSS include Europe’s Galileo, the USA’s NAVSTAR Global Positioning System (GPS), Russia’s Global'naya Navigatsionnaya Sputnikovaya Sistema (GLONASS) and China’s BeiDou Navigation Satellite System.

| Command      | Description  | Return value |
|--------------|---|---|
| AT+CGNSPWR?  | query if GNSS is powerd on | |
| AT+CGNSIPR?  | query the GNSS baud rate | |
| AT+CGNSPWR=1 | power GNSS  on | |
| AT+CGNSINF   | get time and coordinates (if available) | |



http://aprs.gids.nl/nmea/

# Reduce power consumption


When the Rasberry PI uses too much power, the WaveShare Hat does not connect the GSM network.

## Turn off USB/LAN and HDMI output

```diff
--- /etc/rc.local.bak	2023-01-22 19:47:55.906202807 +0000
+++ /etc/rc.local	2023-01-22 19:49:30.933060657 +0000
@@ -17,4 +17,11 @@
   printf "My IP address is %s\n" "$_IP"
 fi

+# Turn off USB/LAN
+# https://raspberrypi-guide.github.io/electronics/power-consumption-tricks
+echo '1-1' |sudo tee /sys/bus/usb/drivers/usb/unbind
+
+# Turn off HDMI output
+sudo /opt/vc/bin/tvservice -o
+
 exit 0
```


## Disable BlueTooth


```bash
sudo systemctl disable hciuart.service
sudo systemctl disable bluetooth.service
```


## Down-clock CPUs

```diff
--- /boot/config.txt.bak	2023-01-22 19:50:32.000000000 +0000
+++ /boot/config.txt	2023-01-22 21:02:28.000000000 +0000
@@ -78,7 +78,15 @@

 [pi4]
 # Run as fast as firmware / board allows
-arm_boost=1
+arm_boost=0

 [all]
 enable_uart=1
+
+# https://www.foxplex.com/sites/raspberry-pi-over-und-underclocking/
+arm_freq=700
+arm_freq_min=100
+core_freq=250
+core_freq_min=75
+sdram_freq=400
+over_voltage=0
```

## Just 1 CPU

```diff
--- /boot/cmdline.txt.bak	2023-01-22 21:01:02.000000000 +0000
+++ /boot/cmdline.txt	2023-01-22 21:02:04.000000000 +0000
@@ -1 +1 @@
-console=tty1 root=PARTUUID=a999dc5f-02 rootfstype=ext4 fsck.repair=yes rootwait
\ No newline at end of file
+console=tty1 maxcpus=1 root=PARTUUID=a999dc5f-02 rootfstype=ext4 fsck.repair=yes rootwait
```


# Run at start-up

```bash
sudo cp drifter-diy.service /etc/systemd/system/
sudo systemctl enable drifter-diy.service # start on boot
sudo systemctl start drifter-diy.service
```


# Switch on/off

* Connection via ssh

``` bash
sudo shutdown -h now
```

Wait that green led is off, then disconnect power supply.

# Start-up sequence

Approximate timings:

* 4 min: to boot Rasberry Pi (under-clocked, with only 1 CPUs)
* 30 s: start WaveShare Hat
* 1 min: wait (so that peak power consumption does not coincides with GSM network registration)
* 1 min: register to GSM network and send first SMS




# Reference


* https://raspberrypi-guide.github.io/electronics/power-consumption-tricks
* https://www.dexterindustries.com/howto/run-a-program-on-your-raspberry-pi-at-startup/
