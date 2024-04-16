
include("motor.jl")

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


