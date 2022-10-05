## First step


First commands:

```
ls
cd directory_name
rm file_name
cat /proc/cpuinfo 
wget some_url
top
```


## Installation

### Operating System


Installing raspberry pi Imager (https://www.raspberrypi.com/software/)

```bash
sudo dpkg -i imager_1.7.2_amd64.deb
rpi-imager
```

And install Rapberry Pi OS Lite (64-bit) onto the SD coard. It is  important to select the 64-bit version.
In the advanced settings (Use `CTRL + SHIFT + X`), one should enable SSH, set a SSH password, configure WiFi by setting the WiFi network name (ESSID) and password.

### Julia


Go to https://julialang.org/downloads/, download and install julia for aarch64.

https://julialang-s3.julialang.org/bin/linux/aarch64/1.8/julia-1.8.0-linux-aarch64.tar.gz

```julia
using Pkg
Pkg.add("LibSerialPort")
```




Install other software:

```bash
sudo apt-get install minicom p7zip-full git emacs-nox pigpiod
sudo timedatectl set-timezone UTC
```

`pigpiod` for GPIO

## Warm-up: On-board led blinking


Start Julia as root

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


```
sudo pigpiod
```

http://aprs.gids.nl/nmea/

