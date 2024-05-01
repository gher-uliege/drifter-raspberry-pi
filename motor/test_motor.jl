using Dates
using Printf
using PiGPIO
using PiGPIO: OUTPUT, INPUT, LOW, HIGH, set_mode


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


# GPIO number for motor L298N

const INPUT1 = 23 # GPIO 23  blue
const INPUT2 = 24  #  GPIO 24 green
const ENABLE_A = 25 # GPIO 25 yellow

const STOP_PIN = 16 # GPIO 16 pin 36

pi=Pi() # connect to pigpiod daemon on localhost


m = Motor(pi,input1 = INPUT1, input2 = INPUT2, enable_A = ENABLE_A)

#=
stop(m)
start(m, forward = true)
start(m, forward = false)


=#

stop(m)

hostname = gethostname()

timestr = Dates.format(Dates.now(),"yyyymmddTHHMMSS")
fname = expanduser("~/temperature-$hostname-$timestr.txt")

f = open(fname,"a")
io = Tee(f,stdout)

function check_stop(pi)
    for i = 1:3
        stop = PiGPIO.read(pi,STOP_PIN) == 1
        if !stop
            return false
        end
        sleep(0.001)
    end

    return true
end



function record_temp(pi,io)
    pos = 0
    stop = false

    while !stop
        pos += 1

        temperature = temp.(w1ids)

        print(io,Dates.now(),',',pos)
        for T in temperature
            print(io,',')
            printstyled(io,@sprintf("%5.3f",T),color=:blue)
        end
        println(io)

        stop = check_stop(pi)

        for ii = 1:10
            stop = check_stop(pi)
            if stop
                println("stop")
                break
            end
            sleep(0.1)
        end
    end
end

set_mode(pi, STOP_PIN, PiGPIO.INPUT)
set_pull_up_down(pi, STOP_PIN, PiGPIO.PUD_UP)

for i = 1:100
    start(m, forward = true)
    record_temp(pi,io)
    stop(m)

    stop(m)
    start(m, forward = false)
    record_temp(pi,io)

    flush(f)
end
stop(m)
close(f)

#=

while true
    #set_pull_up_down(pi, STOP_PIN, PiGPIO.PUD_DOWN)
    @show PiGPIO.read(pi,STOP_PIN)
    sleep(0.1)
end
=#

#=


set_pull_up_down(pi, 23, pigpio.PUD_UP)

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


#=

while true
@show PiGPIO.read(pi,STOP_PIN)
end

=#
