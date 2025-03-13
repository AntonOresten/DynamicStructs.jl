module DynamicStructs

using OrderedCollections: LittleDict

include("utils.jl")
export NoFields, OnlyFields
export propertyvalues, propertypairs

include("properties.jl")

include("dynamic.jl")
export isdynamictype, isdynamic
export @dynamic

end
