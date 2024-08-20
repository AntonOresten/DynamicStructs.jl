const PROPERTIES_FIELD = :_properties

@inline property_dict(x) = getfield(x, PROPERTIES_FIELD)

delproperty!(x, name::Symbol) = (delete!(property_dict(x), name); x)

"""
    @del x.name

Delete the dynamic property `:name` from dynamic type `x`. 
Equivalent to `DynamicStructs.delproperty!(x, :name)`.
"""
macro del(expr)
    expr isa Expr && expr.head == :. || error()
    x, name = expr.args
    return esc(:($delproperty!($x, $name)))
end

"""
    @has x.name

Check if `x` has a property `:name`.
Equivalent to `Base.hasproperty(x, :name)`.
"""
macro has(expr)
    expr isa Expr && expr.head == :. || error()
    x, name = expr.args
    return esc(:(Base.hasproperty($x, $name)))
end

"""
    @dynamic [mutable] struct ... end

## Examples

```julia
using DynamicStructs

@dynamic struct Spaceship
    name::String
end

ship = Spaceship("Hail Mary"; crew=["Grace", "Yao", "Ilyukhina"])

ship.name # "Hail Mary"
ship.crew # ["Grace", "Yao", "Ilyukhina"]

ship.crew = ["Grace"]
ship.fuel = 20906.0

ship.crew # ["Grace"]
ship.fuel # 20906.0

delete!(ship, :fuel)
ship.fuel # ERROR: Spaceship instance has no field or property fuel
```
"""
macro dynamic(expr)
    expr isa Expr && expr.head == :struct || error("`@dynamic` can only be applied to struct definitions")

    struct_def = expr.args[2]
    struct_body = expr.args[3].args

    struct_type, supertype = struct_def isa Expr && struct_def.head == :(<:) ? struct_def.args : (struct_def, :Any)
    struct_name, type_params = struct_type isa Expr && struct_type.head == :curly ? (struct_type.args[1], struct_type.args[2:end]) : (struct_type, [])

    get_type_param_name = tp -> tp isa Expr ? get_type_param_name(tp.args[1]) : tp
    type_param_names = [get_type_param_name(tp) for tp in type_params]

    fields, field_types = [], []
    for f in struct_body
        if f isa Expr && f.head == :(::)
            push!(fields, f.args[1])
            push!(field_types, f.args[2])
        end
    end

    constructor_args = [:($(fields[i])::$(field_types[i])) for i in eachindex(fields)]
    constructors = if isempty(type_param_names)
        quote
            $struct_name($(constructor_args...); kwargs...) =
                new($(fields...), $OrderedDict{Symbol,Any}(kwargs...))
        end
    else
        quote
            $struct_name($(constructor_args...); kwargs...) where {$(type_param_names...)} =
                new{$(type_param_names...)}($(fields...), $OrderedDict{Symbol,Any}(kwargs...))
                
            $struct_name{$(type_param_names...)}($(fields...); kwargs...) where {$(type_param_names...)} =
                new{$(type_param_names...)}($(fields...), $OrderedDict{Symbol,Any}(kwargs...))
        end
    end

    insert_pos = findfirst(x -> x isa Expr && x.head in (:function, :(=)), struct_body)
    insert!(struct_body, isnothing(insert_pos) ? length(struct_body) + 1 : insert_pos, :($PROPERTIES_FIELD::$OrderedDict{Symbol,Any}))

    append!(struct_body, constructors.args)

    return quote
        $(esc(expr))
        $(esc(quote
            Base.propertynames(x::$struct_name, private::Bool=false) =
                ((private ? fieldnames(typeof(x)) : fieldnames(typeof(x))[1:end-1])..., keys($property_dict(x))...)

            function Base.getproperty(x::$struct_name, name::Symbol)
                hasfield(typeof(x), name) && return getfield(x, name)
                name in keys($property_dict(x)) && return $property_dict(x)[name]
                throw(ErrorException("$(typeof(x)) instance has no field or property $name"))
            end

            function Base.setproperty!(x::$struct_name, name::Symbol, value)
                hasfield(typeof(x), name) && return setfield!(x, name, value)
                return setindex!($property_dict(x), value, name)
            end

            Base.hash(x::$struct_name, h::UInt) =
                hash($struct_name, foldr(hash, getfield(x, fieldname) for fieldname in fieldnames($struct_name); init=h))

            Base.:(==)(x::$struct_name, y::$struct_name) = !any(name -> getfield(x, name) != getfield(y, name), fieldnames($struct_name))

            Base.show(io::IO, ::MIME"text/plain", x::$struct_name) = $showdynamic(io, x)
        end))
        nothing
    end
end
