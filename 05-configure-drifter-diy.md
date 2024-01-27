
# Configure `drifter-diy.jl`

The program `drifter-diy.jl` tracks the GPS position, save it in a text file and send the position via SMS. 
It can be configured with the file `drifter-diy.toml` for which a template is available  [`drifter-diy.toml.template`](drifter-diy.toml.template).
Copy the template:

```bash
cd drifter-raspberry-pi
cp drifter-diy.toml.template drifter-diy.toml
```

Edit the file:

```bash
nano drifter-diy.toml
```

You must adapt `phone_number` (receiver of the SMS messages) and `pin`. `local_SMS_service_center` should match the cell phone operator of the SIM card (see [04-GSM-modem.md](04-GSM-modem.md)). 


All phone number should be written using only digits (no space or plus sign).


# Run at start-up


Go to the folder `/home/pi/drifter-raspberry-pi`:

```bash
cd /home/pi/drifter-raspberry-pi
```
Have a look at the file `drifter-diy.service`:

```bash
cat drifter-diy.service
```

This file is a System D (really, that is the real name :-) unit file. It tells the OS, that the julia program `drifter-diy.jl` should be started on boot.

```bash
sudo cp drifter-diy.service /etc/systemd/system/
sudo systemctl enable drifter-diy.service # start on boot
sudo systemctl start drifter-diy.service
```


See the log output:

```
journalctl -u drifter-diy.service -f
```
Restart the service 

```bash
sudo systemctl restart drifter-diy.service
```

