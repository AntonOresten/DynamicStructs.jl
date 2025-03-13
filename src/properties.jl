struct NoFields end
struct OnlyFields end

"""
    Base.propertynames(x, NoFields(), private=false)

Excludes field names.
"""
Base.propertynames(x, ::NoFields, private=false) = Tuple(setdiff(propertynames(x, private), fieldnames(typeof(x))))

"""
    Base.propertynames(x, OnlyFields(), private=false)

Includes only field names.
"""
Base.propertynames(x, ::OnlyFields, private=false) = Tuple(setdiff(fieldnames(typeof(x)), setdiff(propertynames(x, true), propertynames(x, private))))

"""
    propertyvalues(x, args...)

Get a tuple of the current dynamic properties. `args` is passed to `propertynames`.
"""
propertyvalues(x, args...) = Tuple(getproperty(x, name) for name in propertynames(x, args...))

"""
    propertypairs(x, args...)

Get a tuple of the current dynamic properties and their values. `args` is passed to `propertynames`.
"""
propertypairs(x, args...) = Tuple(name => getproperty(x, name) for name in propertynames(x, args...))
