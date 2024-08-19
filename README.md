# DynamicStructs

[![Latest Release](https://img.shields.io/github/release/AntonOresten/DynamicStructs.jl.svg)](https://github.com/AntonOresten/DynamicStructs.jl/releases/latest)
[![Build Status](https://github.com/AntonOresten/DynamicStructs.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/AntonOresten/DynamicStructs.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/AntonOresten/DynamicStructs.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/AntonOresten/DynamicStructs.jl)

```julia
using DynamicStructs

@dynamic struct Person
    name::String
end

p = Person("Robert"; age=42)
p.nickname = "Bob"

println(p.name) # Robert
println(p.age)  # 42
println(p.nickname) # Bob

p.age = 43
println(p.age)  # 43

delete!(p, :nickname)
p.nickname # ERROR
```

## Installation

```julia
using Pkg
Pkg.add("DynamicStructs")
```
