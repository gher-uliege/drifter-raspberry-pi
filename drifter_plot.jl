using Dates
using DelimitedFiles
using PyPlot
using GeoDatasets
using Statistics

function load_track(fname)
    A = readdlm(fname,',');
    time = DateTime.(A[:,1],"yyyy-mm-ddTHH:MM:SS");
    lon = A[:,2]
    lat = A[:,3]

    return time,lon,lat
end

# adapt file name

fname = "/home/abarth/Data/Drifter/drifter01/track-drifter01-20230504T132704.txt" # 3 hours
#fname = "/home/abarth/Data/Drifter/drifter01/track-drifter01-20230504T104608.txt"
#fname = "/home/abarth/Data/Drifter/drifter01/track-drifter01-20230502T182456.txt"
#fname = "/home/abarth/Data/Drifter/drifter01/track-drifter01-20230504T131947.txt"

time,lon,lat = load_track(fname)

t0 = DateTime(year(minimum(time)),month(minimum(time)),day(minimum(time)))

t = time .- t0;
h = Dates.value.(t) / (1000*60*60);

clf()
scatter(lon,lat,10,h); colorbar(label = "hours since $t0 UTC")
xlabel("lon")
ylabel("lat")

res = 'h'
#=
# using PyPlot, GeoDatasets
# This download the file 'gshhg-shp-2.3.7.zip' when called the first time
# Do not interrupt the downloading which can take several minutes.
for (lonc,latc) in GeoDatasets.gshhg(res,[1,5])
    plot(lonc,latc,"-",color="k", linewidth = 0.7)
end
=#
xlim(8.70,8.81)
ylim(42.54,42.594)
gca().set_aspect(1/cosd(mean(ylim())))
