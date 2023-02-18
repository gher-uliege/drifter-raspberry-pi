using Dates
using TOML
using LibSerialPort
using GSMHat
import GSMHat: start_modem, waitfor, enable_gnss, get_gnss, send_message, cmd, unlook

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

sleep(60)
@info "phone number $phone_number"


sp = GSMHat.init(portname, baudrate; pin=pin,
         local_SMS_service_center=local_SMS_service_center)

# power GNSS  on
@info "enable GNSS"
enable_gnss(sp)

# query if GNSS is powerd on
@info "query GNSS"
response = cmd(sp, "AT+CGNSPWR?")

hostname = gethostname()

while true
    # https://web.archive.org/web/20230121160033/https://docs.eseye.com/Content/ELS61/ATCommands/ELS61CREG.htm
    modus,status = GSMHat.registration_status(sp)
    if status in (1,5)
        break
    else
        @info "registration status" modus, status
        sleep(20)
    end
end


@info "send first message"

outbox_messages = []

message = "$hostname ready, switching GNSS on"
push!(outbox_messages,message)

last_message = DateTime(1,1,1)
last_save = DateTime(1,1,1)
fname = expanduser("~/track-$hostname-$(Dates.format(Dates.now(),"yyyymmddTHHMMSS")).txt")
isfile(fname) && rm(fname)
dt_message = Dates.Second(config["message_every_seconds"])
dt_save = Dates.Second(config["save_every_seconds"])
dt_pending_tasks = Dates.Second(10)

@info "saving location every $dt_save in $fname"
@info "sending location every $dt_message to $phone_number"

gnss_fix = false
gnss_retry = 0
sms_retry = 0
time = longitude = latitude = nothing

open(fname,"a+") do f
    while true
        global last_message, last_save, gnss_retry, sms_retry, gnss_fix
        global time, longitude, latitude
        global outbox_messages

        now = Dates.now()

        # GNSS coordinates
        time,longitude,latitude = GSMHat.get_gnss(sp)

        if !isnothing(time) && !isnothing(latitude) && !isnothing(longitude)
            gnss_fix = true
            gnss_retry = 0
        else
            gnss_retry = gnss_retry+1
        end

        # log position if available
        if !isnothing(time) && !isnothing(latitude) && !isnothing(longitude)
            if now - last_message >  dt_message
                message = "sigo vivo, estoy en $longitude, $latitude, $time"
                push!(outbox_messages,message)
                last_message = now
            end

            if now - last_save >  dt_save
                println(f,time,",",longitude,",",latitude)
                flush(f)
                last_save = now
            end
        end

        try
            # get all SMS messages
            messages = GSMHat.get_messages(sp)
            @info "$(length(messages)) message(s)"
            for message in messages
                if strip(lowercase(message.sms_message_body)) == "status"
                    msg = "sigo vivo, estoy en $longitude, $latitude, $time"
                    @info "send status $msg"
                    push!(outbox_messages,msg)
                    GSMHat.delete_message(sp, message.index)
                end
            end
        catch err
            @info "Error while reading SMS message" err
        end


        # send messages from outbox_messages
        while !isempty(outbox_messages)
            message = first(outbox_messages)
            message_send = false

            try
                @info "sending: $message"
                send_message(sp,phone_number,local_SMS_service_center,message)
                message_send = true
                sms_retry = 0
                pop!(outbox_messages)
            catch err
                @info "catched error" err
                sms_retry = sms_retry+1
            end

            if !message_send
                @info "Unable to send message. Will try later again"
                break
            end
        end

        # reset GSM hat if necessary
        if (gnss_retry > 60) && (sms_retry > 60)
            GSMHat.reset(sp)
            GSMHat.unlook(sp,pin)
            # echo state remains off
            gnss_retry = 0
            sms_retry = 0
        end

        if !isnothing(time) && !isnothing(latitude) && !isnothing(longitude) && isempty(outbox_messages)
            # OK, all is fine
            sleep(min(dt_save,dt_message))
        else
            # short sleep
            sleep(min(dt_save,dt_message,dt_pending_tasks))
        end
    end
end

close(sp)
