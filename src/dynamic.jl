mutable struct DynamicProperties
    dict::LittleDict{Symbol,Any,Vector{Symbol},Vector{Any}}
    DynamicProperties(; kwargs...) = isempty(kwargs) ? new() : new(LittleDict{Symbol,Any}(kwargs...))
end

const DYNAMIC_PROPERTIES_FIELD_NAME = :_dynamic_properties

@inline dynamic_properties(x)::DynamicProperties = getfield(x, DYNAMIC_PROPERTIES_FIELD_NAME)
@inline property_dict(x) = dynamic_properties(x).dict

is_property_dict_instantiated(x) = isdefined(dynamic_properties(x), :dict)
is_property_dict_empty(x) = !is_property_dict_instantiated(x) || isempty(property_dict(x))
instantiate_property_dict!(x) = (dynamic_properties(x).dict = LittleDict{Symbol,Any}())

"""
    isdynamictype(T)

Check if `T` is a dynamic type.
"""
isdynamictype(@nospecialize T) = T isa Type && hasfield(T, DYNAMIC_PROPERTIES_FIELD_NAME)

"""
    isdynamic(x)

Check if `x` is an instance of a dynamic type.
"""
isdynamic(@nospecialize x) = isdynamictype(typeof(x))

deconstruct_field(_) = nothing
deconstruct_field(f::Symbol) = f, :Any
function deconstruct_field(f::Expr)
    f.head == :const && return deconstruct_field(f.args[1])
    f.head == :(::) && return f.args[1], f.args[2]
    return nothing
end

isfield(ex) = !isnothing(deconstruct_field(ex))

not_found_error(x, name) = throw(ErrorException("$(typeof(x)) instance has no field or property $name"))

has_inner_constructor(struct_body) =
    any(expr -> expr isa Expr && expr.head in (:function, :(=)), struct_body)

function showkwarg(io::IO, x::T) where T
    fields = propertynames(x, OnlyFields)
    properties = propertynames(x, NoFields)
    print(io, "$T(")
    for (i, fieldname) in enumerate(fields)
        print(io, repr(getfield(x, fieldname)))
        i < length(fields) && print(io, ", ")
    end
    isempty(properties) || print(io, "; ")
    for (i, property) in enumerate(properties)
        print(io, property, "=", repr(getproperty(x, property)))
        i < length(properties) && print(io, ", ")
    end
    print(io, ")")
end

"""
    @dynamic [mutable] struct ... end

## Examples

```julia
using DynamicStructs

@dynamic struct Spaceship
    name::String
end

ship = Spaceship("Hail Mary", crew=["Grace", "Yao", "Ilyukhina"])

ship.name # "Hail Mary"
ship.crew # ["Grace", "Yao", "Ilyukhina"]

ship.crew = ["Grace"] # reassign crew
ship.fuel = 20906.0 # assign fuel

ship.crew # ["Grace"]
ship.fuel # 20906.0

hasproperty(ship, :fuel) # true
delete!(ship, :fuel) # delete fuel
hasproperty(ship, :fuel) # false
ship.fuel # ERROR: Spaceship instance has no field or property fuel
```
"""
macro dynamic(expr::Expr)
    expr.head == :struct || error("`@dynamic` can only be applied to struct definitions")

    struct_def = expr.args[2]
    struct_body = expr.args[3].args

    struct_type, supertype = struct_def isa Expr && struct_def.head == :(<:) ?
        struct_def.args : (struct_def, :Any)
    struct_name, type_params = struct_type isa Expr && struct_type.head == :curly ?
        (struct_type.args[1], struct_type.args[2:end]) : (struct_type, [])

    fields, _ = zip([deconstruct_field(f) for f in struct_body if isfield(f)]...)

    insert!(struct_body, 1, :($DYNAMIC_PROPERTIES_FIELD_NAME::$DynamicProperties))

    kwargs_constructor = if !has_inner_constructor(struct_body)
        quote
            function $(esc(struct_name))($(fields...); kwargs...)
                $(esc(struct_name))($DynamicProperties(; kwargs...), $(fields...))
            end

            Base.show(io::IO, x::$(esc(struct_name))) = showkwarg(io, x)
        end
    else
        nothing
    end

    return quote
        $(esc(expr))

        $kwargs_constructor

        function Base.hasproperty(x::$(esc(struct_name)), name::Symbol)
            hasfield(typeof(x), name) && return true
            !is_property_dict_empty(x) && name in keys(property_dict(x)) && return true
            false
        end
        
        function Base.propertynames(x::$(esc(struct_name)))
            is_property_dict_empty(x) && return fieldnames(typeof(x))[2:end]
            (fieldnames(typeof(x))[2:end]..., property_dict(x).keys...)
        end

        function Base.propertynames(x::$(esc(struct_name)), private::Bool)
            private && is_property_dict_empty(x) && return fieldnames(typeof(x))
            private && return (fieldnames(typeof(x))..., property_dict(x).keys...)
            Base.propertynames(x)
        end

        function Base.getproperty(x::$(esc(struct_name)), name::Symbol)
            hasfield(typeof(x), name) && return getfield(x, name)
            is_property_dict_instantiated(x) && return get(() -> not_found_error(x, name), property_dict(x), name)
            not_found_error(x, name)
        end

        function Base.setproperty!(x::$(esc(struct_name)), name::Symbol, value)
            hasfield(typeof(x), name) && return setfield!(x, name, value)
            !is_property_dict_instantiated(x) && instantiate_property_dict!(x)
            setindex!(property_dict(x), value, name)
            value
        end

        function Base.delete!(x::$(esc(struct_name)), name::Symbol)
            is_property_dict_instantiated(x) && delete!(property_dict(x), name)
            x
        end

        function Base.hash(x::$(esc(struct_name)), h::UInt)
            dp_hash = is_property_dict_empty(x) ? h : hash(property_dict(x), h)
            field_hash = foldr(hash, getfield(x, fieldname) for fieldname in fieldnames(typeof(x))[2:end]; init=dp_hash)
            hash(typeof(x), field_hash)
        end

        function Base.:(==)(x::$(esc(struct_name)), y::$(esc(struct_name)))
            x_empty, y_empty = is_property_dict_empty(x), is_property_dict_empty(y)
            x_empty != y_empty && return false
            !x_empty && !y_empty && property_dict(x) != property_dict(y) && return false
            !any(name -> getfield(x, name) != getfield(y, name), fieldnames(typeof(x))[1:end-1])
        end

        nothing
    end
end

"""
    @construct new(args...)
    @construct new{params...}(args...)

Used to construct an instance of a dynamic type inside of an inner constructor.

Works by inserting a `DynamicProperties` instance as the first argument to the constructor.
"""
macro construct(newargs)
    @assert newargs isa Expr && newargs.head == :call
    new, args = newargs.args[1], newargs.args[2:end]
    :($(esc(new))($(DynamicStructs.DynamicProperties)(), $(args...)))
end
