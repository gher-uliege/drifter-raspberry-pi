using LibSerialPort
using TOML
using Dates
using PiGPIO
using LoggingExtras
using URIs


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
write(sp,"ATE0\r\n")
waitfor(sp,"OK")


@info "test AT command"
write(sp,"AT\r\n")
waitfor(sp,"OK")

@info "unlock SIM"
write(sp, "AT+CPIN=\"$pin\"\r\n")
waitfor(sp,"SMS Ready")


# Check the registration status
write(sp,"AT+CREG?\r\n")
waitfor(sp,"OK")


# Check attach status
write(sp,"AT+CGACT?\r\n")
waitfor(sp,"OK")

# Attach to the network
write(sp,"AT+CGATT=1\r\n")
waitfor(sp,"OK")


# Wait for Attach
# Start task and set the APN
write(sp,"AT+CSTT=\"$APN\"\r\n")
waitfor(sp,"OK")

# Bring up the wireless connection
write(sp,"AT+CIICR\r\n")
waitfor(sp,"OK")


# Wait for bringup
# Get the local IP address
write(sp,"AT+CIFSR\r\n")
waitfor(sp,"\r\n") # no OK in output, just IP address
# like "\r\n10.197.161.140\r\n"



ip = "139.165.57.31"

ip = "52.45.189.24" # httpbin.org
port = 80 # port 80 is the HTTP port.
urlpath = "/upload/Alex"

data = Dict(
    "longitude" => -12,
    "latitude" => 12.2,
    "drifter" => gethostname())

url = URI(scheme = "http", host = ip, path = urlpath,
    query = data,
    )



# Start a TCP connection to remote address
write(sp,"AT+CIPSTART=\"TCP\",\"$ip\",$port\r\n")
waitfor(sp,"CONNECT OK")

method = "post"

if method == "get"
    msg = "GET $url HTTP/1.0\r\n\r\n"
else
    urlencoded = string(URI(;query = data))[2:end]
#Host: $(ip)

    msg = """POST /post HTTP/1.1
Host: httpbin.org
Connection: close
Content-Type: application/x-www-form-urlencoded
Content-length: $(length(urlencoded))

$(urlencoded)
"""
end
write(sp,"AT+CIPSEND\r\n")
waitfor(sp,">")
write(sp,msg)
write(sp, "\x1a\r\n")
out = waitfor(sp,"SEND OK")


write(sp,"AT+CIPCLOSE\r\n")
ret = waitfor(sp,"CLOSED")



