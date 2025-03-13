module DynamicStructs

using Compat: @compat
using OrderedCollections: LittleDict

include("utils.jl")
export NoFields, OnlyFields
export propertyvalues, propertypairs

include("properties.jl")
@compat public Properties

include("dynamic.jl")
export isdynamictype, isdynamic
export @dynamic

end
