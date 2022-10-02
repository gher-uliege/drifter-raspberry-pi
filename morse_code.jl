# run as root on Raspberry Pi


function short(filename)
    write(filename,"1");
    sleep(0.1);
    write(filename,"0");
end

function long(filename)
    write(filename,"1");
    sleep(0.5);
    write(filename,"0");
end



morse_code = Dict(
    'A' => ".-",
	'B' => "-...",
    'C' => "-.-.",
    'D' => "-..",
    'E' => ".",
    'F' => "..-.",
    'G' => "--.",
    'H' => "....",
    'I' => "..",
    'J' => ".---",
    'K' => "-.-",
    'L' => ".-..",
    'M' => "--",
    'N' => "-.",
    'O' => "---",
    'P' => ".--.",
    'Q' => "--.-",
    'R' => ".-.",
    'S' => "...",
    'T' => "-",
    'U' => "..-",
    'V' => "...-",
    'W' => ".--",
    'X' => "-..-",
    'Y' => "-.--",
    'Z' => "--..",
    '1' => ".----",
    '2' => "..---",
    '3' => "...--",
    '4' => "....-",
    '5' => ".....",
    '6' => "-....",
    '7' => "--...",
    '8' => "---..",
    '9' => "----.",
    '0' => "-----",
    ',' => "--..--",
    '.' => ".-.-.-",
    '?' => "..--..",
    '/' => "-..-.",
    '-' => "-....-",
    '(' => "-.--.",
    ')' => "-.--.-"
)


filename = "/sys/class/leds/led0/brightness";
text = "SOS"

write("/sys/class/leds/led0/trigger","none")


for c in text
    code = morse_code[uppercase(c)]
    println(code)

    for i in code
        if i == '-'
            long(filename)
        else i == '.'
            short(filename)
        end

        sleep(0.5);
    end

    sleep(0.7);
end
