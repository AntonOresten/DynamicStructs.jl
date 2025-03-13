mutable struct Properties
    dict::LittleDict{Symbol,Any,Vector{Symbol},Vector{Any}}
    Properties(; kwargs...) = isempty(kwargs) ? new() : new(LittleDict{Symbol,Any}(kwargs...))
end

@inline isinitialized(x::Properties) = isdefined(x, :dict)
@inline initialize!(x::Properties) = (setfield!(x, :dict, LittleDict{Symbol,Any}()))
@inline propertydict(x::Properties) = getfield(x, :dict)

not_found_error(x, name) = throw(ErrorException("$(typeof(x)) instance has no field or property $name"))

_propertynames(x::Properties) = (propertydict(x).keys...,)
Base.propertynames(x::Properties) = isinitialized(x) ? _propertynames(x) : ()

hasnoproperty(x::Properties) = !isinitialized(x) || isempty(propertydict(x))
Base.hasproperty(x::Properties, key::Symbol) = !hasnoproperty(x) && key in _propertynames(x)

function Base.getproperty(x::Properties, key::Symbol, @nospecialize(top = x))
    isinitialized(x) || not_found_error(top, key)
    get(() -> not_found_error(top, key), propertydict(x), key)
end

function Base.setproperty!(x::Properties, key::Symbol, value)
    isinitialized(x) || initialize!(x)
    setindex!(propertydict(x), value, key)
    value
end

function Base.delete!(x::Properties, key::Symbol)
    hasnoproperty(x) || delete!(propertydict(x), key)
    x
end

function Base.show(io::IO, x::Properties)
    show(io, Properties)
    print(io, "(")
    if isinitialized(x)
        for (i, (key, value)) in enumerate(propertydict(x))
            i > 1 && print(io, ", ")
            print(io, key, " = ")
            show(io, value)
        end
    end
    print(io, ")")
end
