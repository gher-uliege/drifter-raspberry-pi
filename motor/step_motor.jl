using PiGPIO
using PiGPIO: OUTPUT, INPUT, LOW, HIGH, set_mode

pi = Pi()


in1 = 16
in2 = 20
in3 = 21
in4 = 26
motor_pins = (in1,in2,in3,in4)

step_sleep = 0.002

# 4096 steps is 360°
step_count = 2*4096

direction = false

# stepper motor sequence
step_sequence = [
    1 0 0 0;
    1 1 0 0;
    0 1 0 0;
    0 1 1 0;
    0 0 1 0;
    0 0 1 1;
    0 0 0 1;
    1 0 0 1;
]

set_mode.(Ref(pi), motor_pins, OUTPUT)

motor_step_counter = 1 ;

function cleanup(pi)
    PiGPIO.write.(Ref(pi), motor_pins, LOW)
end

cleanup(pi)

for i in 1:step_count
    global motor_step_counter

    for pin in 1:length(motor_pins)
        PiGPIO.write(pi,motor_pins[pin], step_sequence[motor_step_counter,pin])
    end      

    if direction
        motor_step_counter -= 1
    else
        motor_step_counter += 1
    end

    motor_step_counter = mod1(motor_step_counter,8)
    
    sleep(step_sleep)
end

cleanup(pi)
