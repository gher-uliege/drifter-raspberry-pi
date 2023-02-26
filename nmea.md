

https://en.wikipedia.org/wiki/NMEA_0183

Enable USB if disabled


```
$ dmesg | grep blox
[    2.164296] usb 1-1.1: Product: u-blox 7 - GPS/GNSS Receiver
[    2.164319] usb 1-1.1: Manufacturer: u-blox AG - www.u-blox.com
```

Check output


```bash
cat /dev/ttyACM0
```



```bash
sudo cp gnss-tracker.service /etc/systemd/system/
sudo systemctl enable gnss-tracker.service # start on boot
sudo systemctl start gnss-tracker.service
```