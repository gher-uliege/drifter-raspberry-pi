# Deployment 🌊 

* Make sure that batteries are fully charged.
* Switch the raspberry pi on only directly before deployment.

* Before and after deployement:
    * Note the exact time
    * Note the battery status

The date in the file name can be incorrect because the raspberry pi has to jet syncronized its clock during boot. Use the dates and times saved in the `track-drifter....txt`file.

Times are saved in UTC.


Transfer files using the following to be entered on your laptop:

```
scp pi@192.168.1.106:/home/pi/file_name.txt  .
```

where `192.168.1.106` is the IP address of your Raspberry Pi and `file_name.txt` the file that you want to transfer.
