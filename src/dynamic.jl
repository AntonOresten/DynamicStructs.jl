get_properties(x) = getfield(x, :_properties)

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
    insert_pos = insert_pos === nothing ? length(struct_body) + 1 : insert_pos
    insert!(struct_body, insert_pos, :(_properties::Properties))

    get_type_param_name = tp -> tp isa Expr ? get_type_param_name(tp.args[1]) : tp
    type_param_names = [get_type_param_name(tp) for tp in type_params]
    struct_name_type_param_names = isempty(type_param_names) ? struct_name : Expr(:curly, struct_name, type_param_names...)

    fields = []
    field_types = []
    for f in struct_body
        if f isa Expr && f.head == :(::) && f.args[1] != :_properties
            push!(fields, f.args[1])
            push!(field_types, f.args[2])
        end
    end

    constructor_params = if !isempty(type_param_names)
        quote
            $struct_name_type_param_names(args...; kwargs...) where {$(type_param_names...)} = 
                new(args..., Properties(; kwargs...))
        end
    end

    constructor_args = [:($(fields[i])::$(field_types[i])) for i in 1:length(fields)]
    constructor_no_params = quote
        $struct_name($(constructor_args...); kwargs...) where {$(type_param_names...)} =
            $struct_name{$(type_param_names...)}($(constructor_args...); kwargs...)
    end


    push!(struct_body, constructor_params, constructor_no_params)

    return quote
        $(esc(expr))
        $(esc(quote
            Base.propertynames(x::$struct_name, private::Bool=false) = ((private ? fieldnames(typeof(x)) : fieldnames(typeof(x))[1:end-1])..., keys(get_properties(x))...)

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
