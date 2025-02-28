
# Update the Raspberry Pi and software configuration

The following steps allow you to update the software running on the Raspberry Pi and the necessary configuration.


* Connect your laptop to the WiFi network `GL-MT300N-V2-c2d`. The password will be provided. Make sure that you stay connected to this access point. Do not make any download while connected this network which is not related to this lecture.

* Power on Raspberry Pi via the USB C cable
* Wait until IP addresses apears in the router
* Open a terminal (follow [this link for more information about opening a terminal](terminal.md))
* Connection to Raspberry Pi via ssh

```bash
ssh pi@192.168.1.6
```

where `192.168.1.6` should be the IP adress from the routers admin page. This IP address will be different for every Raspberry Pi. When you connect the first time, you need to confirm the connection by typing "yes".

Note that everybody can connect to the Raspberry Pi using the username (pi) and password aslong as your are on the same network.

* If you have the error `No route to host`, make sure your laptop is connected to `GL-MT300N-V2-c2d`

* Change the directory to `drifter-raspberry-pi`:


```bash
cd drifter-raspberry-pi
```

* Open the file `drifter-diy.toml` with a text editor:

```bash
nano drifter-diy.toml
```

For nano, `^W` means the key `Control-W` for saving a file
`M-U` means the key `Alt-W` for undo


* Use cursor keys to navigate and change `phone_number` entry in `drifter-diy.toml` to a phone number from your group with __prefix and country code in double quotes__, for example:

```
phone_number = "0032412345678"
```

* Output the file and double check the changes:

```bash
cat drifter-diy.toml
```


* Check the time with the `date` command

* You can change the time using the shell command: `sudo date -s "10 JAN 2021 12:00:00"`


* Restart the julia program recording the position:

```bash
sudo systemctl restart drifter-diy.service
```

* Check the output of the julia program using:

```bash
journalctl -u drifter-diy.service 
```

* Typical message that you will see:

```
Feb 08 13:41:48 drifter02 julia[1356]: ┌ Debug: GNSS response +CGNSINF: 1,0,20250208124147.000,,,,0.00,0.0,0,,,,,,0,0,,,,,
Feb 08 13:41:48 drifter02 julia[1356]: └ @ GSMHat ~/drifter-raspberry-pi/GSMHat.jl:107
```

The GNSS receiver that the right time but not the position.

```
Feb 08 14:02:13 drifter02 julia[5541]: ┌ Debug: GNSS response +CGNSINF: 1,1,20250208130211.000,50.565559,5.570504,164.500,0.00,193.5,2,,1.3,1.6,0.9,,13,9,,,38,,
Feb 08 14:02:13 drifter02 julia[5541]: └ @ GSMHat ~/drifter-raspberry-pi/GSMHat.jl:107
```

The GNSS receiver that the right time, longitude and latitude.

* Stop the Raspberry Pi once finished with the command:

```bash
sudo halt
```
