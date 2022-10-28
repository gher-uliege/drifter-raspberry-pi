using LibSerialPort
using TOML
using Dates
using PiGPIO
using LoggingExtras
using URIs
using GSMHat
import GSMHat: start_modem, waitfor, enable_gnss, get_gnss, send_message, cmd, unlook

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
GSMHat.enable_network(sp,APN)

data = Dict(
    "longitude" => -12,
    "latitude" => 12.2,
    "drifter" => gethostname())


method = "get"
url = "http://139.165.57.31/upload/Alex"

#method = "post"
#url = "http://52.45.189.24/post"


out = GSMHat.http(sp,method,url,data)


