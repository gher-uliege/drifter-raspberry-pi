module GSMHat
using LibSerialPort
using Dates
using PiGPIO
using DelimitedFiles
using URIs
using StringEncodings

const ENCODING = "8859-1"

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
        out *= decode(read(sp),"iso-$ENCODING")
        #out *= String(read(sp))
    end
    return out
end

function cmd(sp,s,expect="OK")
    write(sp, s * "\r\n")
    return split(waitfor(sp,expect,command = s),"\r\n",keepempty=false)
end

function waitfor(sp,expect::Vector{String},maxpoll=Inf; command="")
    out = ""
    i = 0
    while true
        if bytesavailable(sp) > 0
            out *= decode(read(sp),"iso-$ENCODING")
            #out *= String(read(sp))
        end
         #@debug "wait for $expect in: $out"


        if any([occursin(expect_,out) for expect_ in expect])
            break
        end

        if occursin("ERROR",out)
            @warn "out: $out"
            throw(ErrorException(command * ":" * out))
        end

        i = i+1
        if i > maxpoll
            break
        end
        sleep(1)
    end
    return out
end

function waitfor(sp,expect::String,maxpoll=Inf; command = "")
    return waitfor(sp,[expect],maxpoll,command = command)
end

"""
    GSMHat.enable_gnss(sp)

Power GNSS (Global Navigation Satellite System) on. `sp` is connection object from `GSMHat.init`.
"""
enable_gnss(sp) = cmd(sp, "AT+CGNSPWR=1")

"""
    GSMHat.disable_gnss(sp)

Power GNSS (Global Navigation Satellite System) off. `sp` is connection object from `GSMHat.init`.
"""
disable_gnss(sp) = cmd(sp, "AT+CGNSPWR=0")

"""
    time,lon,lat = GSMHat.get_gnss(sp)

Get GNSS (Global Navigation Satellite System) coordinates and time. The function returns
`nothing` if when position and/or time are unknown.
"""
function get_gnss(sp)
    time = longitude = latitude = nothing
    info = cmd(sp, "AT+CGNSINF")
    if length(info) >= 2
        parts = split(info[1],",")

        if length(parts) >= 5
            time = tryparse(DateTime,parts[3],dateformat"yyyymmddHHMMSS.sss")
            latitude = tryparse(Float64,parts[4])
            longitude = tryparse(Float64,parts[5])
        end
        @debug "GNSS response $(info[1])"
    end
    return time,longitude,latitude
end

"""
    GSMHat.send_message(sp,phone_number,local_SMS_service_center,message)

Send the GSM `message` to the number `phone_number` (including coutry code, e.g. 003242345678 for Belgium)
using the local SMS service center (also including country code).
"""
function send_message(sp,phone_number,local_SMS_service_center,message)
    @debug "set local SMS service center"
    cmd(sp, "AT+CSCA=\"$local_SMS_service_center\"")

    @debug "set SMS text mode"
    cmd(sp, "AT+CMGF=1")

    @debug "set phone number"
    cmd(sp, "AT+CMGS=\"$phone_number\"\r\n","\r\n> ")

    @debug "send message $message"
    write(sp, message)

    @debug "terminate message"
    write(sp, "\x1a\r\n")
    waitfor(sp,"OK")
end

"""

GSMHat.get_messages(sp)
"""
function get_messages(sp)
    write(sp,"AT+CMGL=\"ALL\"\r\n")
    ret = waitfor(sp,"OK")
    list = split(ret,"\r\n",keepempty=false)

    if list[end] == "OK"
        pop!(list)
    end
    list_sms = []

    while !isempty(list)
        status = popfirst!(list)
        #a = split(split(status,"+CMGL: ")[2],",")
        if startswith(status,"+CMGL: ")
            a = replace(status,"+CMGL: " => "")
            data = readdlm(IOBuffer(a),',')

            if length(data) >= 5
                index,message_status,address,address_text,service_center_time_stamp = data
                sms_message_body = popfirst!(list)

                sms = (; index,message_status,address,address_text,service_center_time_stamp,sms_message_body)
                push!(list_sms,sms)
            end
        end
    end

    return list_sms
end

"""

GSMHat.delete_messages(sp, status=:received_read)
"""
function delete_messages(sp; status=:received_read)
    if status == :received_read
        flag = 1
    elseif status == :all
        flag = 4
    else
        error("unknown status $status for delete message")
    end
    cmd(sp,"AT+CMGD=1,$flag")
end


"""

GSMHat.delete_message(sp, 1)
"""
function delete_message(sp, index)
    cmd(sp,"AT+CMGD=$index")
end

function unlook(sp,pin)
    @info "query SIM"
    write(sp, "AT+CPIN?\r\n")
    out = waitfor(sp,"OK")

    if !occursin("READY",out)
        @info "unlock SIM"
        write(sp, "AT+CPIN=\"$pin\"\r\n")
        waitfor(sp,[
            "SMS Ready", #
            "SMS DONE", # A7680E
        ])
    else
        @info "SIM already unlocked"
    end
end


"""
    GSMHat.reset(sp)

Reset the modem.
"""
function reset(sp)
    cmd(sp, "AT+CFUN=0")
    cmd(sp, "AT+CFUN=1")
end


"""
    sp = GSMHat.init(portname, baudrate; pin=nothing)

Initialize the WaveShare GSM/GNSS/GPRS Hat pull pin 4 (mapping to port 7) high for 4 seconds and
unlock the SIM card if `pin` is provided.
"""
function init(portname, baudrate; pin=nothing, local_SMS_service_center = nothing)
    # check if modem is on
    sp = LibSerialPort.open(portname, baudrate)
    write(sp,"AT\r\n")
    out = waitfor(sp,"OK",20)
    modem_on = occursin("OK",out)

    if !modem_on
        close(sp)
        @info "start modem"
        start_modem()
        sleep(10)
        sp = LibSerialPort.open(portname, baudrate)
        sleep(2)
    else
        @info "modem already on"
    end

    @info "disable echo"
    cmd(sp,"ATE0")

    @info "test AT command"
    cmd(sp,"AT")

    if pin != nothing
        unlook(sp,pin)
    end


    out = cmd(sp,"AT+CSCS=?")
    if occursin(GSMHat.ENCODING,join(out,""))
        @info "selects the character set $(GSMHat.ENCODING)"
        cmd(sp,"AT+CSCS=\"$(GSMHat.ENCODING)\"")
    else
        @warn "Encoding $(GSMHat.ENCODING) is not supported" out
    end

    if local_SMS_service_center != nothing
       @debug "set local SMS service center"
       #cmd(sp, "AT+CSCA=\"$local_SMS_service_center\"")
    end
    #cmd(sp,"AT+CSCA=?")
    #cmd(sp,"AT+CSCA?")

    return sp
end

"""

GSMHat.enable_network(sp,APN)
"""
function enable_network(sp,APN)
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
end

"""
    # https://web.archive.org/web/20230121160033/https://docs.eseye.com/Content/ELS61/ATCommands/ELS61CREG.htm
"""
function registration_status(sp)
    reg_status = cmd(sp,"AT+CREG?")
    modus,status = parse.(Int,strip.(split(split(reg_status[1],':')[2],',')))
    @info "registration status" reg_status

    return modus,status
end
"""

GSMHat.http(sp,method,url,data)
"""
function http(sp,method,url,data)
    url2 = URI(url)

    @assert url2.scheme == "http"
    ip = url2.host
    urlpath = url2.path

    # port 80 is the default HTTP port
    port = if isempty(url2.port)
        80
    else
        parse(Int,url2.port)
    end


    if method == "get"
        url_ = URI(url2, query = data)
        msg = "GET $url_ HTTP/1.0\r\n\r\n"
    else
        urlencoded = string(URI(;query = data))[2:end]
        #Host: httpbin.org
        #Host: $(ip)
#Connection: close

        msg = """POST $urlpath HTTP/1.1
Connection: close
Host: $(ip)
Content-Type: application/x-www-form-urlencoded
Content-length: $(length(urlencoded))

$(urlencoded)
"""
    end
    # Start a TCP connection to remote address
    cmd(sp,"AT+CIPSTART=\"TCP\",\"$ip\",$port","CONNECT OK")
    write(sp,"AT+CIPSEND\r\n")
    waitfor(sp,">")
    write(sp,msg)
    write(sp, "\x1a\r\n")
#    out = waitfor(sp,"SEND OK")


#    write(sp,"AT+CIPCLOSE\r\n")
    ret = waitfor(sp,"CLOSED")

    return ret
end
end
