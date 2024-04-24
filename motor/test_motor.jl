using Dates
using Printf


struct Tee{TIO <: Tuple} <: IO
    streams::TIO
end

Tee(streams...) = Tee(streams)

function _do_tee(tee, f, xs...)
    for io in tee.streams
        f(io, xs...)
    end
end

Base.write(tee::Tee, x) = _do_tee(tee, write, x)
Base.write(tee::Tee, x::Char) = _do_tee(tee, write, x)
Base.write(tee::Tee, x::Union{SubString{String},String}) = _do_tee(tee, write, x)



include("motor.jl")
include("../temperature_sensor.jl")


w1ids = w1_ids()

#/sys/bus/w1/devices/28-7fa1d445e65b/w1_slave

# GPIO number

INPUT1 = 23 # GPIO 23  blue
INPUT2 = 24  #  GPIO 24 green
ENABLE_A = 25 # GPIO 25 yellow

pi=Pi() # connect to pigpiod daemon on localhost

m = Motor(pi,input1 = INPUT1, input2 = INPUT2, enable_A = ENABLE_A)

#=
stop(m)
start(m, forward = true)
start(m, forward = false)


=#

duration = 90
duration = 50
stop(m)
pos = 0

hostname = gethostname()

fname = expanduser("~/temperature-$hostname-$(Dates.format(Dates.now(),"yyyymmddTHHMMSS")).txt")

f = open(fname,"a")
io = Tee(f,stdout)

function record_temp(io,duration)
    pos = 0
    for j = 1:duration
        pos += 1

        temperature = temp.(w1ids)

        print(io,Dates.now(),',',pos)
        for T in temperature
            print(io,',')
            printstyled(io,@sprintf("%5.3f",T),color=:blue)
        end
        println(io)
        sleep(1)
    end
end

for i = 1:3
    start(m, forward = true)
    record_temp(io,duration)
    stop(m)

    stop(m)
    start(m, forward = false)
    record_temp(io,duration)
end
stop(m)


#=

set_mode(pi, INPUT1, OUTPUT)
set_mode(pi, INPUT2, OUTPUT)
set_mode(pi, ENABLE_A, OUTPUT)

PiGPIO.write(pi, INPUT1, PiGPIO.LOW)
PiGPIO.write(pi, INPUT2, PiGPIO.LOW)

PiGPIO.write(pi, INPUT1, PiGPIO.HIGH)
PiGPIO.write(pi, INPUT2, PiGPIO.LOW)


PiGPIO.write(pi, INPUT1, PiGPIO.LOW)
PiGPIO.write(pi, INPUT2, PiGPIO.HIGH)
=#
