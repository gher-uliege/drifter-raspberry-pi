using LibSerialPort
using TOML

config = TOML.parse(open("drifter.toml"))
phone_number = config["phone_number"]
local_SMS_service_center = config["local_SMS_service_center"]
pin = config["pin"]
APN = config["access_point_network"]

function get(sp)
    out = ""
    if bytesavailable(sp) > 0
        out *= String(read(sp))
    end
    return out
end

echo(sp) = print(get(sp))

function send_message(sp,phone_number,local_SMS_service_center,message)
    write(sp, "AT\r\n")
    sleep(0.1)
    #readline(sp)

    #println(String(read(sp)))


    #write(sp, "ATD0032472056541;\r\n")
    #println(String(read(sp)))

    # Set the format of messages to Text mode
    write(sp, "AT+CMGF=1\r\n")
    sleep(0.1)
    write(sp, "AT+CSCA=\"$local_SMS_service_center\"\r\n")
    sleep(0.1)
    write(sp, "AT+CMGS=\"$phone_number\"\r\n")
    sleep(0.1)
    write(sp, message)
    sleep(0.1)
    write(sp, "\x1a\r\n")
    sleep(0.1)
end



sp = LibSerialPort.open(config["portname"], config["baudrate"])
sleep(2)

write(sp, "AT\r\n")
sleep(0.1)
echo(sp)

write(sp, "AT+CPIN=\"$pin\"\r\n")
sleep(0.1)
echo(sp)

write(sp, "AT+CPIN?\r\n")
sleep(0.1)
echo(sp)


# query if GNSS is powerd on
write(sp, "AT+CGNSPWR?\r\n")
sleep(0.1)
echo(sp)

# power GNSS  on
write(sp, "AT+CGNSPWR=1\r\n")
sleep(0.1)
echo(sp)

# query the GNSS baud rate
write(sp, "AT+CGNSIPR?\r\n")
sleep(0.1)
echo(sp)

#=
# Send data received to UART
write(sp, "AT+CGNSTST=1\r\n")
sleep(0.1)
echo(sp)


for i = 1:10
aa = get(sp)
for line in split(aa,"\r\n")
    
    #if startswith(line,"\$GPGLL")
        println(line)
    #end
end
end

write(sp, "AT+CGNSTST=0\r\n")
sleep(0.1)
echo(sp)

=#

print(aa) 

using Dates

function get_gps(sp)
    for i = 1:10
        try
            write(sp, "AT+CGNSINF\r\n")
            sleep(0.1)
            info = get(sp)
            parts = split(split(info,"\r\n")[2],",")
            
            time = parse(DateTime,parts[3],dateformat"yyyymmddHHMMSS.sss")
            latitude = parse(Float64,parts[4])
            longitude = parse(Float64,parts[5])
            return time,longitude,latitude
        catch
            @info "kapuut: $info"
        end
        sleep(10)
    end
end

time,longitude,latitude = get_gps(sp)

#=
while true
    echo(sp)
end
=#

#=
write(sp, "AT+CGNSPWR=0\r\n")
sleep(0.1)
echo(sp)
=#

message = "sigo vivo, estoy en $longitude, $latitude, $time"
#message = "sigo vivo"

#send_message(sp,phone_number,local_SMS_service_center,message)

function cmd(sp,s)
    write(sp, s * "\r\n")
    sleep(0.1)
    info = get(sp)
    print(info)
    return info
end    

# Check the registration status
cmd(sp,"AT+CREG?")

# Check attach status
cmd(sp,"AT+CGACT?")


# Attach to the network
cmd(sp,"AT+CGATT=1")

# Wait for Attach

# Start task ans set the APN. Check your carrier APN
cmd(sp,"AT+CSTT=\"$APN\"")

# Bring up the wireless connection
cmd(sp,"AT+CIICR")
echo(sp)

# Wait for bringup

# Get the local IP address
cmd(sp,"AT+CIFSR")

ip = "139.165.57.31"

# Start a TCP connection to remote address. Port 80 is TCP.
cmd(sp,"AT+CIPSTART=\"TCP\",\"$ip\",\"80\"")

msg = "GET https://www.m2msupport.net/m2msupport/http_get_test.php HTTP/1.0"
msg = "GET http://$ip/ HTTP/1.0"

# Send the TCP data
write(sp,"AT+CIPSEND=$(length(msg))\r\n")
# wait for >
write(sp,msg)
cmd(sp,"AT+CIPCLOSE")

close(sp)

