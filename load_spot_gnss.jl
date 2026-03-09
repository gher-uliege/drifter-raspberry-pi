using DelimitedFiles
using Dates
using PyPlot

fname = "/mnt/data1/abarth/Downloads/ActivityReport_drifter_20260309_test1.csv"

data,h = readdlm(fname,',',skipstart=5,header=true)
display(h)

time = DateTime.(data[:,2],"m/d/yyyy HH:MM")


timerange = [DateTime(2026,3,9),  DateTime(2026,3,10)]

latlon_str = data[:,4]

# some events (like "Powered On" do not have latitude/longitude

i = @. (timerange[1] <= time < timerange[2]) && (latlon_str != "")

latlon = parse.(Float64,reduce(hcat,split.(latlon_str[i],',')))'

time = time[i]
lat = latlon[:,1]
lon = latlon[:,2]

plot(lon,lat,"-")
