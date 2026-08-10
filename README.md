# DynamicStructs

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://antonoresten.github.io/DynamicStructs.jl/stable/)
[![Coverage](https://codecov.io/gh/AntonOresten/DynamicStructs.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/AntonOresten/DynamicStructs.jl)

DynamicStructs is a Julia package that allows you to create structs with dynamic properties. These properties behave similarly to fields of type `Any` in mutable structs, but are bound to the instance rather than the type, and can be added and deleted at runtime.

## Usage

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

## Performance

Dynamic properties are stored in a dictionary-like structure, which can introduce overhead and type instability compared to static fields. To mitigate this, consider using **function barriers**. Wrapping operations that use dynamic properties in a separate function allows Julia's compiler to infer types more effectively, often resulting in significant speedups and fewer allocations.

```julia
julia> using DynamicStructs, BenchmarkTools

julia> @dynamic struct A end
julia> a = A(x = [1]); b = A(x = [2]);

julia> f(a, b) = a.x .+ b.x
f (generic function with 1 method)

julia> @benchmark f($a, $b)
  memory estimate:  96 bytes
  allocs estimate:  2
  ...

julia> g(x1, x2) = x1 .+ x2
g (generic function with 1 method)

julia> f_barrier(a, b) = g(a.x, b.x)
f_barrier (generic function with 1 method)

julia> @benchmark f_barrier($a, $b)
  memory estimate:  64 bytes
  allocs estimate:  1
  ...
```

## See also

- [DynamicObjects.jl](https://github.com/nsiccha/DynamicObjects.jl)
- [PropertyDicts.jl](https://github.com/JuliaCollections/PropertyDicts.jl)
- [ProtoStructs.jl](https://github.com/BeastyBlacksmith/ProtoStructs.jl)
