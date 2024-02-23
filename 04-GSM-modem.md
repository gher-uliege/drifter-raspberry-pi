## GSM Modem


![raspberry-pi-4-labelled](img/gsm-gprs-gnss-hat-1_6.svg?)

We will need the SIM card in its standard card size (25 mm by 15 mm).

* Please take note of the phone number, PIN and PUK number of the SIM card (you might need them in Calvi)
* Place the SIM card in the WaveShare HAT (gently, very gently). All SIM cards need to be activated (see below)
* Connect the GNSS (GPS) and GSM atennas to the Modem
* Connect the WaveShare HAT with the Rasbperry Pi and fix with screws
* Power on the Rasbperry Pi
* Power on the WaveShare HAT

SIM card activation: by using the procedure "SMS" below, send an SMS to 8804 with:
1. The word IDENT
2. Twice the phone number of the SIM card, separated by space. For example `IDENT 0470123456 0470123456`.

The Modem uses a series of so-called [AT commands](https://en.wikipedia.org/wiki/Hayes_command_set).
All commands start with `AT` (meaning 'attention').
All commands end with the characters `\r\n` (carriage return, line feed). The basic commands used here are the following:


| Command  | Description  | Return value |
|---|---|---|
| AT  | Test Modem  |  OK |
| AT+CPIN? | Check if the SIM card is unlocked | |
| AT+CPIN="1234" | Unlook SIM using pin 1234 | |
| AT+CREG? | Network registration status | |
| ATD0032XXXXXXXXX; | Call a phone number 0032XXXXXXXXX (replacing all X by numbers) | |


## Minicom first tests

First, start the Waveshare HAT (long push on power button PWRKEY)

```bash
sudo minicom -D /dev/ttyS0
```

- Try these commands, they should not return `ERROR` (where 1234 is your pin):

```
AT
# output OK
AT+CPIN="1234"

AT+CREG?
```

Some CREG info: https://web.archive.org/web/20230121160033/https://docs.eseye.com/Content/ELS61/ATCommands/ELS61CREG.htm

- Command to call a phone number (do not forget the final semicolon and the telephone prefix)

```
ATD0032XXXXXXXXX;
```

### SMS


| Command  | Description  | Return value |
|---|---|---|
| AT+CMGF=1  | Set the format of messages to Text mode  |   |
| AT+CSCA="some number"  | set the SMS Service Center Address  |   |
| AT+CMGS="phone_number" | send an SMS message to a GSM phone  (wait for the > prompt and terminate the message with [CTRL+Z](https://en.wikipedia.org/wiki/Substitute_character) |   |

In Julia, SMS messages should be terminated by `"\x1a\r\n"` (CTRL+Z, carriage return, line feed).

Optional, test to send a SMS via minicom:

```
AT
# output OK
AT+CPIN?
+CPIN: READY

# output OK
AT+CMGF=1
# output OK
AT+CSCA="0032475161616"
# output OK
AT+CMGS="0032111111111"
> your message without special characters
>
+CMGS: 9

# output OK
```

where `0032475161616` is the local SMS Service Center number and `0032111111111` its the recipient GSM phone number.


| cell phone operator      | local SMS service center  |
|--------------|---|
| Proximus, Belgium  | 0032475161616 |
| Orange, Belgium  | 0032495002530 |


To exit minicom, type `Ctrl+A x`.

### Global Navigation Satellite System (GNSS)

Examples of GNSS include Europe’s Galileo, the USA’s NAVSTAR Global Positioning System (GPS), Russia’s Global'naya Navigatsionnaya Sputnikovaya Sistema (GLONASS) and China’s BeiDou Navigation Satellite System.

| Command      | Description  | Return value |
|--------------|---|---|
| AT+CGNSPWR?  | query if GNSS is powerd on | |
| AT+CGNSIPR?  | query the GNSS baud rate | |
| AT+CGNSPWR=1 | power GNSS  on | |
| AT+CGNSINF   | get time and coordinates (if available) | |

More information about NMEA is available at http://aprs.gids.nl/nmea/.


# Tests in Julia

Open the serial port:

``` julia
using LibSerialPort
sp = LibSerialPort.open("/dev/ttyS0", 115200)
```

Execute a command:
``` julia
write(sp, "AT\r\n")
```

Read its output
``` julia
if bytesavailable(sp) > 0; println(String(read(sp))); end
# output
# OK
```


