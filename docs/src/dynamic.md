```@meta
CurrentModule = DynamicStructs
```

# Dynamic Structs

Dynamic structs in DynamicStructs.jl extend Julia's standard structs with the ability to add, modify, and delete properties at runtime. This provides flexibility similar to what you might find in dynamic languages while maintaining the type safety and performance benefits of Julia's standard structs.

See [Performance](@ref) for details on performance characteristics and optimization tips, and [Utilities](@ref) for utilities to work with dynamic properties.

```@docs
@dynamic
isdynamictype
isdynamic
```

## Core Concepts

Dynamic structs combine static fields with dynamically added properties:
- **Static fields**: Defined at compile time, type-stable, and efficient
- **Dynamic properties**: Added at runtime, perform like `Any`-typed fields

## Creating Dynamic Structs

Use the `@dynamic` macro to create a dynamic struct:

```@repl dynamic
using DynamicStructs

@dynamic struct GPU
    model::String
    year::Int
end

gpu = GPU("RTX 6000 Ada", 2022, hourly_cost = 0.18)
```

You can also create mutable dynamic structs:

```@repl dynamic
@dynamic mutable struct Person
    name::String
    age::Int
end
```

## Working with Dynamic Properties

### Adding and Accessing Properties

```@repl dynamic
p = Person("Bob", 25, hobby="Reading", location="New York")

p.skills = ["Programming", "Design"];

p.name    # Static field
p.hobby   # Dynamic property
```

### Modifying Properties

```@repl dynamic
p.hobby = "Gaming"

p.age = 26

p
```

### Removing Properties

```@repl dynamic
delete!(p, :hobby)

hasproperty(p, :hobby)
```

## Reflection

Check if a type is dynamic or if an instance is of a dynamic type:

```@repl dynamic
isdynamictype(Person)
isdynamic(p)
```

## Implementation Details

Dynamic structs include a private `__properties` field that stores all dynamic properties in a dictionary-like structure. This field is lazily initialized, meaning no storage is allocated until the first dynamic property is added.

The default constructors of dynamic structs accept keyword arguments for dynamic properties, and a custom `Base.show` method provides a clean representation.

## Overwriting dynamic methods

The `@dynamic` macro defines methods for the following functions:
- `Base.hasproperty`
- `Base.propertynames`
- `Base.getproperty`
- `Base.setproperty!`
- `Base.delete!`
- `Base.hash`
- `Base.:(==)`

This prevents you from defining your own methods without disabling
file precompilation (through `__precompile__(false)`).

Each of the functions above redirect to their respective generic functions in `DynamicStructs`:
- `DynamicStructs.dynamic_hasproperty`
- `DynamicStructs.dynamic_propertynames`
- `DynamicStructs.dynamic_getproperty`
- `DynamicStructs.dynamic_setproperty!`
- `DynamicStructs.dynamic_delete!`
- `DynamicStructs.dynamic_hash`
- `DynamicStructs.dynamic_equality`

These are specifically defined for dynamic structs, and should be used to inherit the default behaviors.

Let us demonstrate with a silly example:

```julia
__precompile__(false) # put in same file

@dynamic struct AddOne end

function Base.getproperty(x::AddOne, name::Symbol)
    DynamicStructs.dynamic_getproperty(x, name) + 1
end
```