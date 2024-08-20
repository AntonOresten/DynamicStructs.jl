module DynamicStructs

using OrderedCollections: OrderedDict

export getproperties
export @dynamic

"""
    getproperties(x; fields=true, private=false)

Get the properties `x`, optionally excluding fields and/or including private properties.
`getproperties(x; fields=true, private)` is equivalent to `Base.propertynames(x, private)`
"""
getproperties(x; fields=true, private=false) = Tuple(fields ? propertynames(x, private) : setdiff(propertynames(x, private), fieldnames(typeof(x))))

include("show.jl")
include("dynamic.jl")

end
