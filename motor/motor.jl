using PiGPIO
using PiGPIO: OUTPUT, INPUT, LOW, HIGH, set_mode


struct Motor
    # connection between input pin L298N and GPIO
    input::NTuple{4,Int}  # 1...4
    enable::NTuple{2,Int}  # A and B
    pi::PiGPIO.Pi
end

function Motor(pi;
               input1 = 0,
               input2 = 0,
               input3 = 0,
               input4 = 0,
               enable_A = 0,
               enable_B = 0,
               frequency = 1000, # Hz
               dutycyle = 255 # 64, 128, 192, 255
               )
    input = (input1,input2,input3,input4)
    enable = (enable_A, enable_B)

    for i = 1:2
        if enable[i] != 0
            p = 2*i-1
            set_mode(pi, input[p], OUTPUT)
            set_mode(pi, input[p+1], OUTPUT)
            set_mode(pi, enable[i], OUTPUT)     

            PiGPIO.write(pi, input[p], LOW)
            PiGPIO.write(pi, input[p+1], LOW)
            
            PiGPIO.set_PWM_frequency(pi,enable[i],frequency)
            PiGPIO.set_PWM_dutycycle(pi, enable[i], dutycyle)
        end
    end
    
    return Motor(input,enable,pi)
end


function stop(m::Motor,i=1)
    p = 2*i-1
    PiGPIO.write(m.pi, m.input[p], LOW)
    PiGPIO.write(m.pi, m.input[p+1], LOW)
end

function start(m::Motor,i=1; forward = true)
    p = 2*i-1
    if forward
        PiGPIO.write(m.pi, m.input[p], LOW)
        PiGPIO.write(m.pi, m.input[p+1], HIGH)
    else
        PiGPIO.write(m.pi, m.input[p], HIGH)
        PiGPIO.write(m.pi, m.input[p+1], LOW)
    end
end




