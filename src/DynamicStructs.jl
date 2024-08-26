module DynamicStructs

using OrderedCollections: LittleDict

export getproperties
export isdynamictype, isdynamic
export @dynamic

"""
    getproperties(x; fields=true, private=false)

Get the properties of `x`, optionally excluding fields and/or including private properties.
`getproperties(x; fields=true, private)` is equivalent to `Base.propertynames(x, private)`
"""
getproperties(x; fields=true, private=false) = Tuple(setdiff(propertynames(x, private), fields ? () : fieldnames(typeof(x))))

include("show.jl")
include("dynamic.jl")
include("deprecated.jl")

end
