using Dates
using Printf

include("temperature_sensor.jl")

w1ids = ["28-7fa1d445e65b","28-1606d445ea95"]


w1id = w1ids[1]


while true
    temperature = temp.(w1ids)

    print(Dates.now(),' ')
    for T in temperature
        printstyled(@sprintf("%5.3f",T),color=:blue)
        print(" ")
    end

    println()
    sleep(1)
end
