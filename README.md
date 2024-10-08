# DynamicStructs

[![Latest Release](https://img.shields.io/github/release/AntonOresten/DynamicStructs.jl.svg)](https://github.com/AntonOresten/DynamicStructs.jl/releases/latest)
[![Build Status](https://github.com/AntonOresten/DynamicStructs.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/AntonOresten/DynamicStructs.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/AntonOresten/DynamicStructs.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/AntonOresten/DynamicStructs.jl)

DynamicStructs is a Julia package that allows you to create structs with dynamic properties. These properties behave similarly to fields of type `Any` in mutable structs, but are bound to the instance rather than the type, and can be added and deleted at runtime.

## Usage

Install from the REPL with `]add DynamicStructs`.

```julia
using DynamicStructs

@dynamic struct Spaceship
    name::String
end

ship = Spaceship("Hail Mary", crew=["Grace", "Yao", "Ilyukhina"])

ship.name # "Hail Mary"
ship.crew # ["Grace", "Yao", "Ilyukhina"]

ship.crew = ["Grace"] # reassign crew
ship.fuel = 20906.0 # assign fuel

ship.crew # ["Grace"]
ship.fuel # 20906.0

hasproperty(ship, :fuel) # true
delete!(ship, :fuel) # delete fuel
hasproperty(ship, :fuel) # false
ship.fuel # ERROR: Spaceship instance has no field or property fuel
```

## Features

- Create structs with both fields and dynamic properties using the `@dynamic` macro.
- Use `mutable struct` to allow for modifying field values.
- Type safety for *fields*.
- Add, modify, and delete dynamic properties at runtime.
- Check if types and instances are dynamic with `isdynamictype` and `isdynamic`:

```julia
julia> (isdynamictype(Spaceship), isdynamic(ship), isdynamic(Spaceship))
(true, true, false)
```

- Get a tuple of the current dynamic properties with `getproperties(ship; fields=false)`:

```julia
julia> getproperties(ship; fields=false)
(:crew,)
```

- Custom show method for pretty-printing (generalized to work with any type using `show_fields_properties(io, x)`):

```julia
julia> ship
Spaceship:
  1 field:
    name::String = "Hail Mary"
  1 property:
    crew::Vector{String} = ["Grace"]
```

## See also

- [DynamicObjects.jl](https://github.com/nsiccha/DynamicObjects.jl)
- [PropertyDicts.jl](https://github.com/JuliaCollections/PropertyDicts.jl)
- [ProtoStructs.jl](https://github.com/BeastyBlacksmith/ProtoStructs.jl)
