
## Check-list


* Does the WaveShare Hat start automatically when the Raspbery Pi start? Led "STA" needs to be ON (and not just "PWR"). If this is not the case after about 1 minute, run the shell commands:

```
sudo systemctl enable pigpiod
sudo systemctl start pigpiod
```


* Is the Raspberry Pi configured in UTC? Run the shell command `timedatectl` to check. If not, run the shell commands:

```
sudo timedatectl set-timezone UTC
```

* Do you get the SMS message `drifterXY ready, switching GNSS on` ? If not, check with the shell commands:

```
journalctl -u drifter-diy.service
```

* Reply to the drifter with the SMS message `status` (all lower case, no space at the end). Do you get an answer?


## Debugging

### Raspberry Pi does not connect to WiFi

* Context Raspberry PI with an ethernet cable to router
* Get the IP address from the router and SSH into the Raspberry Pi 
* Run `sudo nmtui` and select `Activate a connection`, select WiFi and enter password
* More information is available at https://pimylifeup.com/setting-up-raspberry-pi-wifi/

### Other issues

The SD cart can be mounted in a Linux system and the log files can be inspected.

Log files are available under, e.g.:

/var/log/journal/cea2410f2a2549828d4c623c99ee548f 
$ journalctl --file user-1000.journal --utc

/var/log/



## Entering PUK

```
AT+CPIN="PUK","new_PIN"
```

For example `AT+CPIN="12341234","1234"` where the new pin can be the same as the old pin.



 ## Decoding SMS messages

```julia
using GSMHat, TOML
confname ="drifter-diy.toml"
config = open(confname) do f
               TOML.parse(f)
           end
sp = GSMHat.init(config["portname"], config["baudrate"]; pin=config["pin"],
                local_SMS_service_center=config["local_SMS_service_center"])
messages = GSMHat.get_messages(sp)

decodemsg(str) = join(Char.(parse.(Int,[str[(4*i) .+ (1:4)] for i = 0:(length(str)÷4-1)],base=16)))
decodemsg(messages[1].sms_message_body)
# output
# "Cher client Proximus, votre carte prépayée numéro...
```

## SSH connection without keys

```bash
ssh -o PubkeyAuthentication=no -o PreferredAuthentications=password  -A pi@192.168.0.199
```
