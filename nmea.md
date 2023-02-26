# GNSS (GPS) Tracker


The GNSS/GPS USB device uses the [NMEA protocol](https://en.wikipedia.org/wiki/NMEA_0183).

If is important to enable USB if it is disabled.

Check if device is found during boot:

```
$ dmesg | grep blox
[    2.164296] usb 1-1.1: Product: u-blox 7 - GPS/GNSS Receiver
[    2.164319] usb 1-1.1: Manufacturer: u-blox AG - www.u-blox.com
```

Check output of the follow command to the the NMEA codes:

```bash
cat /dev/ttyACM0
```

Automatically enable on start-up:

```bash
sudo cp gnss-tracker.service /etc/systemd/system/
sudo systemctl enable gnss-tracker.service # start on boot
sudo systemctl start gnss-tracker.service
```
