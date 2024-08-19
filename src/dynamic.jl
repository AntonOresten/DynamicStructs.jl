get_properties(x) = x.properties

macro dynamic(expr)
    expr.head == :struct || error("@dynamic can only be applied to struct definitions")

    struct_def = expr.args[2]
    struct_body = expr.args[3].args

    struct_type, supertype = if struct_def isa Expr && struct_def.head == :(<:)
        struct_def.args[1], struct_def.args[2]
    else
        struct_def, :Any
    end

    struct_name, type_params = if struct_type isa Expr && struct_type.head == :curly
        struct_type.args[1], struct_type.args[2:end]
    else
        struct_type, []
    end

    insert_pos = findfirst(x -> x isa Expr && x.head in (:function, :(=)), struct_body)
    insert!(struct_body, insert_pos === nothing ? length(struct_body) + 1 : insert_pos, :(properties::Properties))

    type_param_names = [tp isa Expr ? tp.args[1] : tp for tp in type_params]
    struct_name_type_params = isempty(type_params) ? struct_name : Expr(:curly, struct_name, type_param_names...)

    constructor_no_type_params = :($struct_name(args...; kwargs...) = $struct_name(args..., Properties(; kwargs...)))

    constructor_type_params = if !isempty(type_params)
        struct_name_type_params = Expr(:curly, struct_name, type_params...)
        quote
            $struct_name_type_params(args...; kwargs...) where {$(type_params...)} = 
                $struct_name_type_params(args..., Properties(; kwargs...))
        end
    end

    return quote
        $(esc(expr))
        $(esc(quote
            $constructor_no_type_params
            $constructor_type_params
        end))
        $(esc(quote
            Base.propertynames(x::$struct_name, private::Bool=false) = (fieldnames(typeof(x))..., keys(get_properties(x))...)

            function Base.getproperty(x::$struct_name, name::Symbol)
                hasfield(typeof(x), name) && return getfield(x, name)
                name in keys(get_properties(x)) && return get_properties(x)[name]
                throw(ErrorException("$(typeof(x)) instance has no field or property $name"))
            end

            function Base.setproperty!(x::$struct_name, name::Symbol, value)
                hasfield(typeof(x), name) && return setfield!(x, name, value)
                return setindex!(get_properties(x), value, name)
            end

            Base.delete!(x::$struct_name, name::Symbol) = (delete!(get_properties(x), name); x)

            Base.show(io::IO, ::MIME"text/plain", x::$struct_name) = $showdynamic(io, x)
        end))
    end
end
