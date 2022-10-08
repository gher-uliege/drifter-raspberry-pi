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

echo(sp) = @info get(sp)

function cmd(sp,s,expect=nothing)
    info0 = get(sp)

    write(sp, s * "\r\n")

    while bytesavailable(sp) == 0
        sleep(0.1)
    end
    info = get(sp)
    @info info
    if !isnothing(expect)
        if !occursin(expect,info)
            @warn "expect $expect got $info"
        end
    end
    return info
end

function waitfor(sp,expect)
    out = ""
    while true
        if bytesavailable(sp) > 0
            out *= String(read(sp))
        end
        @info "wait for: $out"
        if occursin(expect,out)
            break
        end
        sleep(0.1)
    end
    return out
end

function send_message(sp,phone_number,local_SMS_service_center,message)
    write(sp, "AT+CMGF=1\r\n")
    write(sp, "AT+CSCA=\"$local_SMS_service_center\"\r\n")
    get(sp)

    if bytesavailable(sp) > 0
        String(read(sp))
    end

    write(sp, "AT+CMGS=\"$phone_number\"\r\n")
    waitfor(sp,"\r\n> ")

    write(sp, message)
    write(sp, "\x1a\r\n")
    get(sp)
end

function get_gnss(sp)
    response = get(sp)
    @info response
    while true
        write(sp, "AT+CGNSINF\r\n")
        sleep(0.1)
        response = get(sp)
        info = split(response,"\r\n")
        if length(info) >= 2
            parts = split(info[2],",")
            @info "parts: $parts"

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

confname = joinpath(dirname(@__FILE__),"drifter.toml")
config =
    open(confname) do f
        TOML.parse(f)
    end

phone_number = config["phone_number"]
local_SMS_service_center = config["local_SMS_service_center"]
pin = config["pin"]
APN = config["access_point_network"]

@info "phone_number $phone_number"

start_modem()
sleep(2)

sp = LibSerialPort.open(config["portname"], config["baudrate"])
sleep(2)

#=
write(sp, "ATE0\r\n")
get(sp)

write(sp, "AT\r\n")
get(sp)

cmd(sp,"AT","OK")

write(sp, "AT\r\n")
sleep(0.1)
echo(sp)
=#

write(sp, "AT+CPIN=\"$pin\"\r\n")
echo(sp)

write(sp, "AT+CPIN?\r\n")
sleep(0.1)
echo(sp)


# power GNSS  on
write(sp, "AT+CGNSPWR=1\r\n")
sleep(0.1)
echo(sp)


# query if GNSS is powerd on
write(sp, "AT+CGNSPWR?\r\n")
sleep(0.1)
echo(sp)

# get first position
time,longitude,latitude = get_gnss(sp)

hostname = gethostname()

last_message = DateTime(1,1,1)
last_save = DateTime(1,1,1)
fname = "track-$hostname-$(Dates.format(Dates.now(),"yyyymmddTHHMMSS")).txt"
isfile(fname) && rm(fname)
dt_message = Dates.Minute(10)
dt_save = Dates.Minute(1)

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
