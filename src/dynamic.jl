mutable struct DynamicProperties
    dict::LittleDict{Symbol,Any}
    DynamicProperties(; kwargs...) = isempty(kwargs) ? new() : new(LittleDict{Symbol,Any}(kwargs...))
end

const DYNAMIC_PROPERTIES_FIELD_NAME = :_dynamic_properties

@inline dynamic_properties(x)::DynamicProperties = getfield(x, DYNAMIC_PROPERTIES_FIELD_NAME)
@inline property_dict(x) = getfield(dynamic_properties(x), :dict)

is_property_dict_instantiated(x) = isdefined(dynamic_properties(x), :dict)
is_property_dict_empty(x) = !is_property_dict_instantiated(x) || isempty(property_dict(x))
instantiate_property_dict!(x) = setfield!(dynamic_properties(x), :dict, LittleDict{Symbol,Any}())

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

delproperty!(x, name::Symbol) = (delete!(property_dict(x), name); x)

"""
    @del x.name

Delete the dynamic property `:name` from dynamic type `x`. 
Equivalent to `DynamicStructs.delproperty!(x, :name)`.
"""
macro del(expr::Expr)
    expr isa Expr && expr.head == :. || throw(ArgumentError("Expression must be of the form `x.name`"))
    x, name = expr.args
    return :(delproperty!($(esc(x)), $name))
end

"""
    @has x.name

Check if `x` has a property `:name`.
Equivalent to `Base.hasproperty(x, :name)`.
"""
macro has(expr::Expr)
    expr isa Expr && expr.head == :. || throw(ArgumentError("Expression must be of the form `x.name`"))
    x, name = expr.args
    return :(Base.hasproperty($(esc(x)), $name))
end

_deconstruct_field(_) = nothing
_deconstruct_field(f::Symbol) = f, :Any
function _deconstruct_field(f::Expr)
    f.head == :const && return _deconstruct_field(f.args[1])
    f.head == :(::) && return f.args[1], f.args[2]
    return nothing
end

_isfield(ex) = !isnothing(_deconstruct_field(ex))

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

@has ship.fuel # true
@del ship.fuel # delete fuel
@has ship.fuel # false
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

    get_type_param_name = tp -> tp isa Expr ? get_type_param_name(tp.args[1]) : tp
    type_param_names = [get_type_param_name(tp) for tp in type_params]

    fields, field_types = zip([_deconstruct_field(f) for f in struct_body if _isfield(f)]...)

    field_type_asserts = [Expr(:(::), f, ft) for (f, ft) in zip(fields, field_types)]
    constructors = if isempty(type_param_names)
        quote
            $struct_name($(field_type_asserts...); kwargs...) =
                new($(fields...), $DynamicProperties(; kwargs...))
        end
    else
        quote
            $struct_name($(field_type_asserts...); kwargs...) where {$(type_param_names...)} =
                new{$(type_param_names...)}($(fields...), $DynamicProperties(; kwargs...))
                
            $struct_name{$(type_param_names...)}($(fields...); kwargs...) where {$(type_param_names...)} =
                new{$(type_param_names...)}($(fields...), $DynamicProperties(; kwargs...))
        end
    end

    push!(struct_body, :($DYNAMIC_PROPERTIES_FIELD_NAME::$DynamicProperties))
    append!(struct_body, constructors.args)

    return quote
        $(esc(expr))

        function Base.propertynames(x::$(esc(struct_name)))
            is_property_dict_empty(x) && return fieldnames(typeof(x))[1:end-1]
            (fieldnames(typeof(x))[1:end-1]..., property_dict(x).keys...)
        end

        function Base.propertynames(x::$(esc(struct_name)), private::Bool)
            private && is_property_dict_empty(x) && return fieldnames(typeof(x))
            private && return (fieldnames(typeof(x))..., property_dict(x).keys...)
            Base.propertynames(x)
        end

        function Base.getproperty(x::$(esc(struct_name)), name::Symbol)
            hasfield(typeof(x), name) && return getfield(x, name)
            is_property_dict_instantiated(x) && name in keys(property_dict(x)) && return @inbounds getindex(property_dict(x), name)
            throw(ErrorException("$(typeof(x)) instance has no field or property $name"))
        end

        function Base.setproperty!(x::$(esc(struct_name)), name::Symbol, value)
            hasfield(typeof(x), name) && return setfield!(x, name, value)
            !is_property_dict_instantiated(x) && instantiate_property_dict!(x)
            setindex!(property_dict(x), value, name)
        end

        function Base.hash(x::$(esc(struct_name)), h::UInt)
            dp_hash = is_property_dict_empty(x) ? h : hash(property_dict(x), h)
            field_hash = foldr(hash, getfield(x, fieldname) for fieldname in fieldnames(typeof(x))[1:end-1]; init=dp_hash)
            hash(typeof(x), field_hash)
        end

        function Base.:(==)(x::$(esc(struct_name)), y::$(esc(struct_name)))
            x_empty, y_empty = is_property_dict_empty(x), is_property_dict_empty(y)
            x_empty != y_empty && return false
            !x_empty && !y_empty && property_dict(x) != property_dict(y) && return false
            !any(name -> getfield(x, name) != getfield(y, name), fieldnames(typeof(x))[1:end-1])
        end

        Base.show(io::IO, x::$(esc(struct_name))) = showdynamic(io, x)
        Base.show(io::IO, ::MIME"text/plain", x::$(esc(struct_name))) = show_fields_properties(io, x)

        nothing
    end
end
