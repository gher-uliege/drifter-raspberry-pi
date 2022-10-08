using LibSerialPort
using TOML
using Dates
using PiGPIO



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

echo(sp) = print(get(sp))

function cmd(sp,s,expect=nothing)
    info0 = get(sp)

    write(sp, s * "\r\n")
#    sleep(0.1)

    while bytesavailable(sp) == 0
    end
    info = get(sp)
    print(info)
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
        print("out",out)
        if occursin(expect,out)
            break
        end
        sleep(0.1)
    end
    return out
end

function send_message(sp,phone_number,local_SMS_service_center,message)
    #write(sp, "AT\r\n")
    #sleep(0.1)
    #readline(sp)

    #println(String(read(sp)))


    #write(sp, "ATD0032472056541;\r\n")
    #println(String(read(sp)))

    # Set the format of messages to Text mode
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

println("starting ", Dates.now())

config = TOML.parse(open("drifter.toml"))
phone_number = config["phone_number"]
local_SMS_service_center = config["local_SMS_service_center"]
pin = config["pin"]
APN = config["access_point_network"]

println("phone_number ",phone_number)

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

print(aa)

=#



function get_gnss(sp)
    response = get(sp)
    @info response
    for i = 1:10
        write(sp, "AT+CGNSINF\r\n")
        sleep(0.1)
        response = get(sp)
        info = split(response,"\r\n")
        if length(info) >= 2
            parts = split(info[2],",")
            @show parts

            if (length(parts) >= 5) && (parts[3] !== "") && (parts[4] !== "") && (parts[5] !== "")
                time = parse(DateTime,parts[3],dateformat"yyyymmddHHMMSS.sss")

                latitude = parse(Float64,parts[4])
                longitude = parse(Float64,parts[5])
                return time,longitude,latitude
            end
        end
        println("GNSS response" ,response)
        sleep(10)
    end
end


time,longitude,latitude = get_gnss(sp)

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
            println("sending: ",message)
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


#message = "sigo vivo, estoy en $longitude, $latitude, $time"
#print(message)

#=
message = "sigo vivo"

send_message(sp,phone_number,local_SMS_service_center,message)
=#



#=

# Check the registration status
cmd(sp,"AT+CREG?")

# Check attach status
cmd(sp,"AT+CGACT?")
get(sp)

# Attach to the network
cmd(sp,"AT+CGATT=1")

# Wait for Attach

# Start task ans set the APN. Check your carrier APN
cmd(sp,"AT+CSTT=\"$APN\"")
echo(sp)


# Bring up the wireless connection
cmd(sp,"AT+CIICR")
echo(sp)

# Wait for bringup

# Get the local IP address
cmd(sp,"AT+CIFSR")
echo(sp)

ip = "139.165.57.31"

# Start a TCP connection to remote address. Port 80 is TCP.
cmd(sp,"AT+CIPSTART=\"TCP\",\"$ip\",\"80\"")
echo(sp)

msg = "GET https://www.m2msupport.net/m2msupport/http_get_test.php HTTP/1.0"
msg = "GET http://$ip/ HTTP/1.0"

# Send the TCP data
write(sp,"AT+CIPSEND=$(length(msg))\r\n")
sleep(10)
# wait for >
echo(sp)
write(sp,msg)
cmd(sp,"AT+CIPCLOSE")

close(sp)

=#
