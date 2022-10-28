using Dates
using TOML
using LibSerialPort
using GSMHat
import GSMHat: start_modem, waitfor, enable_gnss, get_gnss, send_message

using Logging
debug_logger = ConsoleLogger(stderr, Logging.Debug);
global_logger(debug_logger)


@info "starting $(Dates.now())"

confname = joinpath(dirname(@__FILE__),"drifter-diy.toml")
config =
    open(confname) do f
        TOML.parse(f)
    end

phone_number = config["phone_number"]
local_SMS_service_center = config["local_SMS_service_center"]
pin = config["pin"]
APN = config["access_point_network"]
portname = config["portname"]
baudrate = config["baudrate"]

@info "phone number $phone_number"


sp = GSMHat.init(portname, baudrate; pin=pin)


# power GNSS  on
@info "enable GNSS"
enable_gnss(sp,true)

# query if GNSS is powerd on
@info "query GNSS"
write(sp, "AT+CGNSPWR?\r\n")
waitfor(sp,"OK")

hostname = gethostname()

@info "send first message"
message = "$hostname ready, switching GNSS on"
send_message(sp,phone_number,local_SMS_service_center,message)

@info "get GNSS location"
# get first position
time,longitude,latitude = get_gnss(sp)

#message = "first fix $longitude, $latitude, $time"
#@info "sending: $message"
#send_message(sp,phone_number,local_SMS_service_center,message)

last_message = DateTime(1,1,1)
last_save = DateTime(1,1,1)
fname = expanduser("~/track-$hostname-$(Dates.format(Dates.now(),"yyyymmddTHHMMSS")).txt")
isfile(fname) && rm(fname)
dt_message = Dates.Second(config["message_every_seconds"])
dt_save = Dates.Second(config["save_every_seconds"])

@info "saving location every $dt_save in $fname"
@info "sending location every $dt_message to $phone_number"

open(fname,"a+") do f
    while true
        global last_message, last_save

        now = Dates.now()
        time,longitude,latitude = get_gnss(sp)

        if now - last_message >  dt_message
            message = "sigo vivo, estoy en $longitude, $latitude, $time"
            @info "sending: $message"
            send_message(sp,phone_number,local_SMS_service_center,message)
            last_message = now
        end

        if now - last_save >  dt_save
            println(f,time,",",longitude,",",latitude)
            flush(f)
            last_save = now
        end

        sleep(min(dt_save,dt_message))
    end
end

close(sp)
