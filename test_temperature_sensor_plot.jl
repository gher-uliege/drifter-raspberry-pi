using Dates
using Printf
using Plots

include("temperature_sensor.jl")

w1ids = ["28-7fa1d445e65b","28-1606d445ea95"]


w1id = w1ids[1]

temperature = zeros(0,length(w1ids))
time = DateTime[]

while true
    global temperature, time
    t = temp.(w1ids)
    temperature = vcat(temperature, t')
    push!(time,Dates.now())
    
    print(time[end],' ')
    for T in temperature[end,:]
        printstyled(@sprintf("%5.3f",T),color=:blue)
        print(" ")
    end

    i=1
    pl = plot(time,temperature[:,i],label="sensor $i")
    for i = 2:length(w1ids)
        pl = plot!(time,temperature[:,i],label="sensor $i")
    end
    display(pl)
    println()
    sleep(1)
end
