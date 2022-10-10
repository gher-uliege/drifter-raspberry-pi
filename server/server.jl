using TOML
using Tables
using Dates
using Genie
using HTTP
using Genie.Router
using URIs
import SearchLight: AbstractModel, DbId, save!
import Base: @kwdef
import SearchLight.Migrations: create_table, column, primary_key, add_index, drop_table
using SearchLight
using SearchLightPostgreSQL
using Genie, Genie.Requests, Genie.Renderer.Json
import Genie.Renderer.Json: json


function init_db() 
    create_table(:position4s) do
        [
            primary_key()
            column(:name, :string, limit = 80)
            column(:longitude, :decimal)
            column(:latitude, :decimal)
            column(:time, :timestamp)
        ]
    end
end

#drop_table(:position4s)


@kwdef mutable struct Position4 <: AbstractModel
  id::DbId = DbId()
  name::String = ""
  longitude::Float64 = 0.
  latitude::Float64 = 0.
  time::DateTime = DateTime(1,1,1,0,0,0)
end


#Genie.Generator.db_support()

SearchLight.Configuration.load()
SearchLight.connect()

#=
SearchLight.query("SELECT * FROM position4s")

p = Position4(
    name = "drifter01", 
    longitude = 12.2,
    latitude = 12.3,
    time = DateTime(2001,1,1,2,3,2,123))
              
save!(p)

all(Position4)
=#

route("/api/v1/insert") do    
    p = Position4(
        name = filter(isascii,params(:name)),
        longitude = parse(Float64,params(:longitude)),
        latitude = parse(Float64,params(:latitude)),
        time = parse(DateTime,params(:time)),
    )              
    save!(p)

    "OK"
end

route("/api/v1/drifter/:name::String") do
    drifter_name = params(:name)
    res = find(Position4,SQLWhereExpression("name = ?",drifter_name))
    
    Dict(
        "longitude" => getproperty.(res,:longitude),
        "latitude" => getproperty.(res,:latitude),
        "time" => getproperty.(res,:time),
    ) |> json
end

up(8888)

