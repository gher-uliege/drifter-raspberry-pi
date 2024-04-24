

const w1basedir = "/sys/bus/w1/devices/"

function w1_slave(w1id)
    joinpath(w1basedir,w1id,"w1_slave")
end

function w1_ids()
    filter(w1id -> isfile(w1_slave(w1id)),readdir(w1basedir))
end

function temp(w1id)
    fname = "/sys/bus/w1/devices/$w1id/w1_slave"
    lines = readlines(fname)
    p,strv = split(lines[2][3*9+1:end],'=')
    return parse(Int,strv) / 1000
end
