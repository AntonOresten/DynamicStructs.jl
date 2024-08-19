# DynamicStructs

[![Latest Release](https://img.shields.io/github/release/AntonOresten/DynamicStructs.jl.svg)](https://github.com/AntonOresten/DynamicStructs.jl/releases/latest)
[![Build Status](https://github.com/AntonOresten/DynamicStructs.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/AntonOresten/DynamicStructs.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/AntonOresten/DynamicStructs.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/AntonOresten/DynamicStructs.jl)

DynamicStructs is a Julia package that allows you to create structs with dynamic properties. These properties behave like fields of type `Any` in mutable structs, but they are bound to the instance rather than the type, and can be added and deleted at runtime.

## Usage

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

delete!(ship, :fuel)
ship.fuel # ERROR: Spaceship instance has no field or property fuel
```

## Features

- Create structs with both static fields and dynamic properties
- Add, modify, and delete dynamic properties at runtime
- Full type safety for static properties
- Dynamic properties use `OrderedDict` under the hood, maintaining insertion order for predictable iteration
- Custom show method for pretty-printing:

```julia
julia> ship
Spaceship:
  1 field:
    name::String = "Hail Mary"
  1 property:
    crew::Vector{String} = ["Grace"]
```

## Installation

```julia
using Pkg
Pkg.add("DynamicStructs")
```

## Implementation details

The `@dynamic` macro adds a `_properties::DynamicStructs.Properties` field to the struct definition. The `DynamicStructs.Properties` type wraps an `OrderedDict{Symbol, Any}` that stores the dynamic properties. The `Base.getproperty` and `Base.setproperty!` methods for the new type are defined to access this dictionary.

A `show` method for contexts like the REPL is defined to display the fields and dynamic properties of the new type in a nice and clear format.

## See also

- [DynamicObjects.jl](https://github.com/nsiccha/DynamicObjects.jl)
- [PropertyDicts.jl](https://github.com/JuliaCollections/PropertyDicts.jl)
- [ProtoStructs.jl](https://github.com/BeastyBlacksmith/ProtoStructs.jl)
