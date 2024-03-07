

The SD cart can be mounted in a Linux system and the log files can be inspected.

Log files are available under:

/var/log/journal/cea2410f2a2549828d4c623c99ee548f 
$ journalctl --file user-1000.journal --utc

/var/log/



 # Decoding SMS messages

```julia
using GSMHat
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

