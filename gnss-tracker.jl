using NMEA
using Dates

save_each = Dates.Second(60)

hostname = gethostname()
fname = expanduser("~/gnss-tracker-$hostname-$(Dates.format(Dates.now(),"yyyymmddTHHMMSS")).csv")
devicename = "/dev/ttyACM0"


last_saved = typemin(DateTime)

dev = open(devicename,"r")
dev_lines = eachline(dev)
fields = [:longitude,:latitude,:fix_quality,:num_sats,:HDOP]
delim = ','
string_quote = '"'


@info "writing to $fname every $save_each"

open(fname,"w") do fout
    println(fout,join(["time",string.(fields)...],delim))

    for line in dev_lines
        global last_saved

        if isempty(line)
            continue
        end
        @debug "parse line" line

        try
            record = NMEA.parse(line)

            if record isa NMEA.GGA
               time = Dates.now()

                if time > last_saved + save_each
                    print(fout,time)
                    print(fout,delim)
                    for (i,f) in enumerate(fields)
                        field = getproperty(record,f)
                        if field isa Number
                            print(fout,field)
                        else
                            print(fout,string_quote,field,string_quote)
                        end
                        if i < length(fields)
                            print(fout,delim)
                        end
                    end
                    println(fout)
                    flush(fout)
                    last_saved = time
                    sleep(save_each)
                end
            end
        catch err
            if err isa ArgumentError
                @debug "failing to parse record" err
            else
                rethrow(err)
            end
        end
    end
end
