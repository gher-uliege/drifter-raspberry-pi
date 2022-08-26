## First step


First commands:

```
ls
cd directory_name
rm file_name
cat /proc/cpuinfo 
wget some_url
top
```


## Install Julia

Go to:
https://julialang.org/downloads/

https://julialang-s3.julialang.org/bin/linux/aarch64/1.8/julia-1.8.0-linux-aarch64.tar.gz



## Warm-up: On-board led blinking


Start Julia as root

```julia
write("/sys/class/leds/led0/trigger","none")
write("/sys/class/leds/led0/brightness","1")
write("/sys/class/leds/led0/brightness","0")
```

Blinking leds:

```julia
filename = "/sys/class/leds/led0/brightness"; 

while true; 
   write(filename,"0"); 
   sleep(0.5); 
   write(filename,"1"); 
   sleep(0.5);
end
```

Idea: What about to implement [Morse code](https://en.wikipedia.org/wiki/Morse_code) ?
