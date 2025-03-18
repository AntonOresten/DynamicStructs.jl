```@meta
CurrentModule = DynamicStructs
```

# Utilities

DynamicStructs defines a few functions to simplify working with dynamic properties, as well as the more general case where `propertynames(x) != fieldnames(typeof(x))`.

```@docs
NoFields
OnlyFields
Base.propertynames
propertyvalues
propertypairs
```

## Examples

```@repl
using DynamicStructs

@dynamic struct Spaceship
    name::String
end

ship = Spaceship("Blip-A"; pressure=28.0)

propertynames(ship, OnlyFields)

propertynames(ship, NoFields)

propertyvalues(ship)

propertyvalues(ship, NoFields)

propertypairs(ship)

propertypairs(ship, OnlyFields)

ship == Spaceship(propertyvalues(ship, OnlyFields)...; propertypairs(ship, NoFields)...)
```
