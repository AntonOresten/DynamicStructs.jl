module DynamicStructs

using OrderedCollections: OrderedDict

export @dynamic, get_properties

include("properties.jl")
include("show.jl")
include("dynamic.jl")

end
