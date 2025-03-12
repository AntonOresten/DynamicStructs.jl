module DynamicStructs

using OrderedCollections: LittleDict

include("properties.jl")
export NoFields, OnlyFields
export propertyvalues, propertypairs

include("dynamic.jl")
export isdynamictype, isdynamic
export @dynamic, @construct

end
