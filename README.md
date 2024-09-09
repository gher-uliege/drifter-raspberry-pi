
<img src="https://github.com/user-attachments/assets/22ea3f79-fd94-4903-8872-f0c43a4a01b1" width="400">



# Table of contents:


1. [💾 software installation](01-software-installation.md)
1. [⚡ reduce power consumption](02-reduce-power-consumption.md)
1. [🚨 blinking leds](03-blinking-leds.md)
1. [☎️ GSM modem](04-GSM-modem.md)
1. [⚙️ configure `drifter-diy.jl`](05-configure-drifter-diy.md)
1. [🌊 notes for deployment](06-deployment.md)
1. [💻 Analysis of drifter data](https://tinyurl.com/drifter-julia) with the [sample data](https://dox.ulg.ac.be/index.php/s/fMcSM6wLjXAVYLR/download)
    and [bathymetry](https://dox.ulg.ac.be/index.php/s/9ZwWDbsTgCwgS90/download).

## Switch on/off

* Connection via ssh

``` bash
sudo shutdown -h now
```

Wait that green led is off, then disconnect power supply.

## Start-up sequence

Approximate timings:

* 4 min: to boot Rasberry Pi (under-clocked, with only 1 CPUs)
* 30 s: start WaveShare Hat
* 1 min: wait (so that peak power consumption does not coincides with GSM network registration)
* 1 min: register to GSM network and send first SMS




# Reference


* https://raspberrypi-guide.github.io/electronics/power-consumption-tricks
* https://www.dexterindustries.com/howto/run-a-program-on-your-raspberry-pi-at-startup/
