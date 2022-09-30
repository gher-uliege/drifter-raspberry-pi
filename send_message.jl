using LibSerialPort
using TOML

config = TOML.parse(open("drifter.toml"))
phone_number = config["phone_number"]
local_SMS_service_center = config["local_SMS_service_center"]
pin = config["pin"]

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
    readline(sp)

    println(String(read(sp)))


    #write(sp, "ATD0032472056541;\r\n")
    println(String(read(sp)))

    write(sp, "AT+CMGF=1\r\n")
    write(sp, "AT+CSCA=\"$local_SMS_service_center\"\r\n")
    write(sp, "AT+CMGS=\"$phone_number\"\r\n")
    write(sp, message)
    write(sp, "\x1a\r\n")
end



sp = LibSerialPort.open(config["portname"], config["baudrate"])
sleep(2)

write(sp, "AT\r\n")
echo(sp)

write(sp, "AT+CPIN=\"$pin\"\r\n")
echo(sp)

write(sp, "AT+CPIN?\r\n")
echo(sp)


# query of GNSS is powerd on
write(sp, "AT+CGNSPWR?\r\n")
sleep(0.1)
echo(sp)

# power GNSS  on
write(sp, "AT+CGNSPWR=1\r\n")
sleep(0.1)
echo(sp)

# query of GNSS baud rate
write(sp, "AT+CGNSIPR?\r\n")
sleep(0.1)
echo(sp)

write(sp, "AT+CGNSTST=1\r\n")
sleep(0.1)
echo(sp)

aa = get(sp)
print(aa) 



#=
message = "hola guapa soy el drifter"
send_message(sp,phone_number,local_SMS_service_center,message)

close(sp)
=#
