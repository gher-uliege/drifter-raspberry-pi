## Installation

![raspberry-pi-4-labelled](img/raspberry-pi-4-labelled.png)

Raspberry Pi hardware (source: https://www.raspberrypi.com/)

### Operating System

* You need a compute with a SD card reader
* Installing [raspberry pi Imager](https://www.raspberrypi.com/software/) and follow the instruction on this page.
* For Ubuntu, install the deb file with:

```bash
sudo dpkg -i imager_1.7.2_amd64.deb
rpi-imager
```

* Install **Rapberry Pi OS Lite (64-bit)** onto the SD coard. It is important (for julia) to select the 64-bit version.
* In the advanced settings (Use `CTRL + SHIFT + X`), see https://github.com/gher-uliege/drifter-raspberry-pi/tree/main/img for screenshots.
     * hostname in the form of `drifterXY` (for example dirfter02, but everybody should use a different number).
     * one enable SSH (use password authentication)
     * set username: `pi` (keep default)
     * set password: (will be provided) 
     * SSID: __TP-Link_1465__
     * WiFi password:  (will be provided, __different from your account password__)
     * Time zone: Europe/Brussels
     * Make sure that Enable Telemetry is __unchecked__. 
* Put the SD card, in the SD card slot of the Rapberry Pi
* Power-on the Rapberry Pi (via the USB C connector)

## Connect to the Raspberry pi

* Determine the Raspberry pi IP address (see WiFi router access logs) 
* Open a terminal:
     * [Ubuntu/Linux](https://ubuntu.com/tutorials/command-line-for-beginners#3-opening-a-terminal)
     * [Mac OS](https://support.apple.com/guide/terminal/open-or-quit-terminal-apd5265185d-f365-44cb-8b09-71a064a42125/mac)
     * [Windows](https://learn.microsoft.com/en-us/powershell/scripting/windows-powershell/starting-windows-powershell?view=powershell-7.3#from-the-start-menu) and  see also [Get started with OpenSSH for Windows](https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse?tabs=gui)      
* __Connect your laptop to the same WiFi network as the raspbery Pi__ (this is important, otherwise you cannot connect to the Raspberry Pi) 
* Connect via SSH:

```bash
ssh pi@192.168.1.6
```

where `192.168.1.6` should be the IP adress from the routers admin page. This IP address will be different for every  Raspberry pi.

## First step


These are the basic shell commands:

| Command  | Description  |
|---|---|
| `ls` | list all files in current directory |
| `cd directory_name` | change directory |
| `rm file_name` | remove a file |
| `cat /proc/cpuinfo` | see the content of a text file |
| `wget some_url` | download a file from URL |
| `top`  | see which process is running |


### Julia


Go to https://julialang.org/downloads/, *copy* the download link for julia for *aarch64*. Download julia directly on the Rasbperry Pi:

```bash
wget URL
```

where `URL` the julia archive from the https://julialang.org/downloads/.

```bash
sudo tar -C /opt -xvf FILE_NAME
```

where `FILE_NAME` is the downloaded file.

```bash
sudo ln -s /opt/julia-XYZ/bin/julia /usr/local/bin
```

where `julia-XYZ` is the directory that was created when extracting the compressed archive.
Start Julia by runnng `julia` and install the following package:

```julia
using Pkg
Pkg.add("LibSerialPort")
Pkg.add("PiGPIO")
Pkg.add("URIs")
Pkg.add("StringEncodings")
Pkg.add("NMEA")
```


Create the folder `~/.julia/config/` and the file `~/.julia/config/startup.jl` with the content:

```julia
push!(LOAD_PATH, joinpath(ENV["HOME"],"drifter-raspberry-pi"))
```

Install other software: pigpiod is a daemon for controling the general purpose I/O pins (GPIO). We also set the timezone to UTC.

```bash
sudo apt-get install minicom p7zip-full git emacs-nox pigpiod
sudo timedatectl set-timezone UTC
sudo systemctl enable pigpiod
sudo systemctl start pigpiod
```

Get the source code:

```bash
git clone https://github.com/gher-uliege/drifter-raspberry-pi.git
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
All commands end with the characters `\r\n` (carriage return, line feed). The basic commands used here are the following:


| Command  | Description  | Return value |
|---|---|---|
| AT  | Test Modem  |  OK |
| AT+CPIN? | Check if the SIM card is unlocked | |
| AT+CPIN="1234" | Unlook SIM using pin 1234 | |
| AT+CREG? | Network registration status | |
| ATD0032XXXXXXXXX; | Call a phone number 0032XXXXXXXXX (replacing all X by numbers) | |


## Minicom first tests

First, start the Waveshare HAT (long push on power button PWRKEY)

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

To exit minicom, Ctrl+A x

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
| AT+CSCA="some number"  | set the SMS Service Center Address  |   |
| AT+CMGS="phone_number" | send an SMS message to a GSM phone  (wait for the > prompt and terminate the message with [CTRL+Z](https://en.wikipedia.org/wiki/Substitute_character) |   |

In Julia, SMS messages should be terminated by `"\x1a\r\n"` (CTRL+Z, carriage return, line feed).

Optional, test to send a SMS via minicom:

```
AT+CPIN?
+CPIN: READY

OK
AT+CMGF=1
OK
AT+CSCA="0032475161616"
OK
AT+CMGS="0032111111111"
> your message without special characters
>
+CMGS: 9

OK
```

where `0032475161616` is the SMS Service Center Address and `0032111111111` its the recipient CSM phone number.

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
--- /boot/config.txt.bak	2023-02-18 15:30:02.000000000 +0000
+++ /boot/config.txt	2023-02-21 20:28:54.000000000 +0000
@@ -78,7 +78,14 @@
 
 [pi4]
 # Run as fast as firmware / board allows
-arm_boost=1
+arm_boost=0
 
 [all]
 enable_uart=1
+
+# https://www.foxplex.com/sites/raspberry-pi-over-und-underclocking/
+arm_freq=700
+core_freq=250
+core_freq_min=75
+sdram_freq=400
+over_voltage=0
```

## Just 1 CPU

Add `maxcpus=1` to this file, keep the rest of the line. Do __not__ change the identifier following `root=PARTUUID=`.

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


See the log output:

```
journalctl -u drifter-diy.service -f
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
