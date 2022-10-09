using LibSerialPort
using TOML
using Dates
using PiGPIO
using LoggingExtras

const date_format = "yyyy-mm-dd HH:MM:SS"

timestamp_logger(logger) = TransformerLogger(logger) do log
  merge(log, (; message = "$(Dates.format(now(), date_format)) $(log.message)"))
end

ConsoleLogger(stdout, Logging.Debug) |> timestamp_logger |> global_logger

function start_modem()
    pi = Pi();
    pin = 4; # mapping to port 7
    PiGPIO.write(pi, pin, PiGPIO.ON);
    sleep(4);
    PiGPIO.write(pi, pin, PiGPIO.OFF)
end

function get(sp)
    out = ""
    if bytesavailable(sp) > 0
        out *= String(read(sp))
    end
    return out
end

function waitfor(sp,expect)
    out = ""
    while true
        if bytesavailable(sp) > 0
            out *= String(read(sp))
        end
        @debug "wait for $expect in: $out"
        if occursin(expect,out)
            break
        end
        sleep(0.5)
    end
    return out
end

function enable_gnss(sp,state)
    if state
        # power GNSS  on
        write(sp, "AT+CGNSPWR=1\r\n")
        waitfor(sp,"OK")
    else
        # power GNSS  off
        write(sp, "AT+CGNSPWR=0\r\n")
        waitfor(sp,"OK")
    end
end

function send_message(sp,phone_number,local_SMS_service_center,message)
    write(sp, "AT+CMGF=1\r\n")
    waitfor(sp,"OK")

    write(sp, "AT+CSCA=\"$local_SMS_service_center\"\r\n")
    waitfor(sp,"OK")

    write(sp, "AT+CMGS=\"$phone_number\"\r\n")
    waitfor(sp,"\r\n> ")
    write(sp, message)
    write(sp, "\x1a\r\n")
    waitfor(sp,"OK")
end

function get_gnss(sp)
    response = get(sp)
    @debug response
    while true
        write(sp, "AT+CGNSINF\r\n")
        response = waitfor(sp,"OK")

        info = split(response,"\r\n")
        if length(info) >= 2
            parts = split(info[2],",")
            @debug "parts: $parts"

            if length(parts) >= 5
                time = tryparse(DateTime,parts[3],dateformat"yyyymmddHHMMSS.sss")
                latitude = tryparse(Float64,parts[4])
                longitude = tryparse(Float64,parts[5])

                if !isnothing(time) && !isnothing(latitude) && !isnothing(longitude)
                    return time,longitude,latitude
                end
            end
        end
        @debug "GNSS response $response"
        sleep(10)
    end
end


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

@info "phone number $phone_number"

start_modem()
sleep(2)

sp = LibSerialPort.open(config["portname"], config["baudrate"])
sleep(2)

@info "disable echo"
write(sp,"ATE0")
waitfor(sp,"OK")

@info "test AT command"
write(sp,"AT")
waitfor(sp,"OK")

@info "unlock SIM"
write(sp, "AT+CPIN=\"$pin\"\r\n")
waitfor(sp,"SMS Ready")

@info "query SIM"
write(sp, "AT+CPIN?\r\n")
waitfor(sp,"OK")

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

message = "first fix $longitude, $latitude, $time"
@info "sending: $message"
send_message(sp,phone_number,local_SMS_service_center,message)


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
