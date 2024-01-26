## Warm-up: On-board led blinking


Start Julia as root

```bash
sudo julia
```

Enter the following Julia commands:

```julia
write("/sys/class/leds/ACT/trigger","none")
write("/sys/class/leds/ACT/brightness","1")
write("/sys/class/leds/ACT/brightness","0")
```
The first command, will take control over the green led. The second and third command switch it on and off.

Blinking leds:

```julia
filename = "/sys/class/leds/ACT/brightness";

while true;
   write(filename,"0");
   sleep(0.5);
   write(filename,"1");
   sleep(0.5);
end
```

Idea: What about implementing [Morse code](https://en.wikipedia.org/wiki/Morse_code) ?
