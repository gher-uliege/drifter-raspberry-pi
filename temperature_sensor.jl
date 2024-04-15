function temp(w1id)
    fname = "/sys/bus/w1/devices/$w1id/w1_slave"
    lines = readlines(fname)
    p,strv = split(lines[2][3*9+1:end],'=')
    return parse(Int,strv) / 1000
end
