module GSMHat
using LibSerialPort
using Dates
using PiGPIO

# using LoggingExtras

# const date_format = "yyyy-mm-dd HH:MM:SS"

# timestamp_logger(logger) = TransformerLogger(logger) do log
#   merge(log, (; message = "$(Dates.format(now(), date_format)) $(log.message)"))
# end

# ConsoleLogger(stdout, Logging.Debug) |> timestamp_logger |> global_logger

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


function waitfor(sp,expect::Vector{String},maxpoll=Inf)
    out = ""
    i = 0
    while true
        if bytesavailable(sp) > 0
            out *= String(read(sp))
        end
        @debug "wait for $expect in: $out"


        if any([occursin(expect_,out) for expect_ in expect])
            break
        end

        if occursin("ERROR",out)
            @warn "out: $out"
            throw(ErrorException(out))
        end
        
        i = i+1
        if i > maxpoll
            break
        end
        sleep(0.5)
    end
    return out
end

function waitfor(sp,expect::String,maxpoll=Inf)
    return waitfor(sp,[expect],maxpoll)
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
    @debug "set SMS text mode"
    write(sp, "AT+CMGF=1\r\n")
    waitfor(sp,"OK")

    @debug "set local SMS service center"
    write(sp, "AT+CSCA=\"$local_SMS_service_center\"\r\n")
    waitfor(sp,"OK")

    @debug "set phone number"
    write(sp, "AT+CMGS=\"$phone_number\"\r\n")
    waitfor(sp,"\r\n> ")
    
    @debug "send message $message"
    write(sp, message)

    @debug "terminate message"
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

end
