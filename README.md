


Table of contents:


1. [💾 software installation](01-software-installation.md)
1. [⚡ reduce power consumption](02-reduce-power-consumption.md)
1. [💡 blinking leds](03-blinking-leds.md)
1. [☎️ GSM modem](04-GSM-modem.md)
1. [⚙️ configure `drifter-diy.jl`](05-configure-drifter-diy.md)


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
