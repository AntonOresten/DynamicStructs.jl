module DynamicStructs

using OrderedCollections

export getproperties
export isdynamictype, isdynamic
export @has, @get, @get!, @del!
export @dynamic

@deprecate var"@del" var"@del!"

"""
    getproperties(x; fields=true, private=false)

Get the properties of `x`, optionally excluding fields and/or including private properties.
`getproperties(x; fields=true, private)` is equivalent to `Base.propertynames(x, private)`
"""
getproperties(x; fields=true, private=false) = Tuple(setdiff(propertynames(x, private), fields ? () : fieldnames(typeof(x))))

include("show.jl")
include("dynamic.jl")

end
