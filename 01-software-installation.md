## Installation

![raspberry-pi-4-labelled](img/raspberry-pi-4-labelled.png)

Raspberry Pi hardware (source: https://www.raspberrypi.com/)

### Operating System

* You need a compute with a SD card reader
* Installing [raspberry pi Imager](https://www.raspberrypi.com/software/) and follow the instructions on this page.
* For Ubuntu, install the deb file with:

```bash
sudo dpkg -i imager_1.7.2_amd64.deb
rpi-imager
```

* Install **Raspberry Pi OS Lite (64-bit)** onto the SD card (available under **Raspberry Pi OS (other)**).
     * It is important (for julia) to select the **64-bit version**.
     * The "Lite" version means that a desktop environement (which we do not need) is not pre-installed.
* In the advanced settings (Use `CTRL + SHIFT + X`), see https://github.com/gher-uliege/drifter-raspberry-pi/tree/main/img for screenshots.
     * hostname in the form of __`drifterXY`__ (for example dirfter02, but everybody should use a different number, replace XY with your 2-digit group number).
     * __enable SSH__ (use password authentication)
     * set username: `pi` (keep default)
     * set password: (will be provided)
     * SSID: __GL-MT300N-V2-c2d__
     * WiFi password:  (will be provided, it is __different from your account password__)
     * Time zone: Europe/Brussels
     * Make sure that Enable Telemetry is __unchecked__.
* Confirm with "Next", confirm that you want to apply costumized setting, double check that you write to the SD storage
* Put the SD card in the SD card slot of the Rapberry Pi
* Power-on the Raspberry Pi (via the USB C connector)

## Connect to the Raspberry Pi

* Determine the Raspberry pi IP address (see WiFi router access logs)
* Open a terminal:
     * [Ubuntu/Linux](https://ubuntu.com/tutorials/command-line-for-beginners#3-opening-a-terminal)
     * [Mac OS](https://support.apple.com/guide/terminal/open-or-quit-terminal-apd5265185d-f365-44cb-8b09-71a064a42125/mac)
     * [Windows](https://learn.microsoft.com/en-us/powershell/scripting/windows-powershell/starting-windows-powershell?view=powershell-7.3#from-the-start-menu) and  see also [Get started with OpenSSH for Windows](https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse?tabs=gui)
* __Connect your laptop to the same WiFi network as the Raspbery Pi__ (this is important, otherwise you cannot connect to the Raspberry Pi)
* Connect via SSH:

```bash
ssh pi@192.168.1.6
```

where `192.168.1.6` should be the IP adress from the routers admin page. This IP address will be different for every Raspberry Pi. When you connect the first time, you need to confirm the connection by typing "yes".

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

Most of the code is written in julia, therefore we need to install julia.
Download julia directly on the Rasbperry Pi:

```bash
wget https://julialang-s3.julialang.org/bin/linux/aarch64/1.10/julia-1.10.7-linux-aarch64.tar.gz
```

1.10.7 is the current LTS version (as of November 2024). This command will extract all files from the downloaded archive `julia-1.10.7-linux-aarch64.tar.gz` and install julia in `/opt/julia-1.10.7`:

```bash
sudo tar -C /opt -xvf julia-1.10.7-linux-aarch64.tar.gz
```

where `julia-1.10.7-linux-aarch64.tar.gz` is the downloaded file. We put a symbolic link of the julia program in `/usr/local/bin` to point to the installation directory `/opt/julia-1.10.7/bin/`.

```bash
sudo ln -s /opt/julia-1.10.7/bin/julia /usr/local/bin
```

So that the operating systems, knows where to find the julia program.

Start Julia by running `julia` and install the following packages:

```julia
using Pkg
Pkg.add(["LibSerialPort","PiGPIO","URIs","StringEncodings","NMEA"])
```

| Package  | Description  |
|---|---|
| `LibSerialPort` | issue commands over the serial port (WaveShare Hat is connected over the serial port) |
| `PiGPIO` | Control the GPIO pin from julia |
| `URIs` | manipulate web links |
| `StringEncodings` | handle different string encodings |
| `NMEA` | Implement the [NMEA protocol](https://en.wikipedia.org/wiki/NMEA_0183) for reading the GNSS/GPS information |

Create the folder `~/.julia/config/` and the file `~/.julia/config/startup.jl` with a text editor like nano, emacs or vim.

```bash
mkdir ~/.julia/config/
nano ~/.julia/config/startup.jl
```

[Here](https://www.nano-editor.org/dist/latest/cheatsheet.html) is a list of shortcuts for nano.

The file  `~/.julia/config/startup.jl` should have the following content:

```julia
push!(LOAD_PATH, joinpath(ENV["HOME"],"drifter-raspberry-pi"))
```

Now everytime julia starts, it knows where to the code in the folder `drifter-raspberry-pi`.

Install other software: pigpiod is a daemon for controling the general purpose I/O pins (GPIO). We also set the timezone to UTC.

```bash
sudo apt-get update
sudo apt-get install --yes minicom p7zip-full git emacs-nox pigpiod
sudo timedatectl set-timezone UTC
sudo systemctl enable pigpiod
sudo systemctl start pigpiod
```

Get the source code:

```bash
git clone https://github.com/gher-uliege/drifter-raspberry-pi.git
```


## Enable serial port

We will connect to the GSM model via the serial port. The serial port has to be enabled using the
shell command `raspi-config`:

```bash
sudo raspi-config
```

* Select `3 Interface Options`
* Select  `I5 Serial Port`
* Answer *no* to the question `Would you like a login shell to be accessible over serial?`
* Answer *yes* to the question `Would you like the serial port hardware to be enabled?`
* Check that the output is:

```
The serial login shell is disabled
The serial interface is enabled
```

Exit the configuration tool and confirm that you want to reboot if asked.
