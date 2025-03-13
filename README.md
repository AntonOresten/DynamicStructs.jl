# DynamicStructs

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://antonoresten.github.io/DynamicStructs.jl/stable/)
[![Coverage](https://codecov.io/gh/AntonOresten/DynamicStructs.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/AntonOresten/DynamicStructs.jl)

DynamicStructs is a Julia package that allows you to create structs with dynamic properties. These properties behave similarly to fields of type `Any` in mutable structs, but are bound to the instance rather than the type, and can be added and deleted at runtime.

## Usage

Install from the REPL with `]add DynamicStructs`.

```julia
julia> using DynamicStructs

julia> @dynamic struct Spaceship
           name::String
       end

julia> ship = Spaceship("Hail Mary", crew=["Grace", "Yao", "Ilyukhina"])
Spaceship("Hail Mary"; crew=["Grace", "Yao", "Ilyukhina"])

julia> ship.name, ship.crew
("Hail Mary", ["Grace", "Yao", "Ilyukhina"])

julia> ship.crew = ["Grace"]; # reassign crew

julia> ship.fuel = 20906.0; # assign fuel

julia> Spaceship("Hail Mary"; crew=["Grace"], fuel=20906.0)

julia> hasproperty(ship, :fuel)
true

julia> delete!(ship, :fuel) # delete fuel
Spaceship("Hail Mary"; crew=["Grace"])

julia> hasproperty(ship, :fuel)
false
```

## See also

- [DynamicObjects.jl](https://github.com/nsiccha/DynamicObjects.jl)
- [PropertyDicts.jl](https://github.com/JuliaCollections/PropertyDicts.jl)
- [ProtoStructs.jl](https://github.com/BeastyBlacksmith/ProtoStructs.jl)
