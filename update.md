

* connect your laptop to `GL-MT300N-V2-c2d`


* power on Raspberry Pi via the USB C cable
* wait until IP addresses apears in the router
* make sure your laptop is connected to `GL-MT300N-V2-c2d` otherwise your will get errors like `No route to host`.
* connection to Raspberry Pi via ssh

* 
cd drifter-raspberry-pi

* nano drifter-diy.toml

`^W` means the key `Control-W` for saving a file
`M-U` means the key `Alt-W` for undo

* output the file

cat drifter-diy.toml

* use cursor keys
* change `phone_number` entry in drifter-diy.toml to a phone number from your group with prefix and country code in double quotes, for example:

```
phone_number = "0032412345678"
```

* check the time with the `date` command


sudo systemctl restart drifter-diy.service

* What is the 
journalctl -u drifter-diy.service 

* typical message that you will see:

```
Feb 08 13:41:48 drifter02 julia[1356]: ┌ Debug: GNSS response +CGNSINF: 1,0,20250208124147.000,,,,0.00,0.0,0,,,,,,0,0,,,,,
Feb 08 13:41:48 drifter02 julia[1356]: └ @ GSMHat ~/drifter-raspberry-pi/GSMHat.jl:107
```


```
Feb 08 14:02:13 drifter02 julia[5541]: ┌ Debug: GNSS response +CGNSINF: 1,1,20250208130211.000,50.565559,5.570504,164.500,0.00,193.5,2,,1.3,1.6,0.9,,13,9,,,38,,
Feb 08 14:02:13 drifter02 julia[5541]: └ @ GSMHat ~/drifter-raspberry-pi/GSMHat.jl:107
```

sudo halt
