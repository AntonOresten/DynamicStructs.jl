struct Properties <: AbstractDict{Symbol,Any}
    _dict::OrderedDict{Symbol,Any}
end

get_dict(p::Properties) = getfield(p, :_dict)

Properties() = Properties(OrderedDict())
Properties(pairs::Vararg{Pair{Symbol}}) = Properties(OrderedDict(name => value for (name, value) in pairs))
Properties(args...; kwargs...) = Properties(args..., kwargs...)

Base.length(p::Properties) = length(get_dict(p))
Base.iterate(p::Properties, args...) = iterate(get_dict(p), args...)
Base.keys(p::Properties) = keys(get_dict(p))
Base.values(p::Properties) = values(get_dict(p))
Base.get(p::Properties, name::Symbol, default) = get(get_dict(p), name, default)

Base.getindex(p::Properties, name::Symbol) = getindex(get_dict(p), name)
Base.setindex!(p::Properties, value, name::Symbol) = setindex!(get_dict(p), value, name)

function Base.delete!(p::Properties, name::Symbol)
    delete!(get_dict(p), name)
    return p
end

Base.propertynames(p::Properties, ::Bool=false) = (collect(keys(p))...,)

Base.getproperty(p::Properties, name::Symbol) = getindex(p, name)
Base.setproperty!(p::Properties, name::Symbol, value) = setindex!(p, value, name)
