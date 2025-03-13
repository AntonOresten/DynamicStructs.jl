using Base.Meta: isexpr

uncurly(x) = isexpr(x, :curly) ? x.args[1] : x

"""
    isdynamictype(T)

Check if `T` is a dynamic type.
"""
isdynamictype(@nospecialize T) = false

"""
    isdynamic(x)

Check if `x` is an instance of a dynamic type.
"""
isdynamic(@nospecialize x) = isdynamictype(typeof(x))

const PROPERTIES_FIELD_NAME = :__properties

@inline properties(x) = getfield(x, PROPERTIES_FIELD_NAME)

deconstruct_field(_) = nothing
deconstruct_field(f::Symbol) = f, :Any
function deconstruct_field(f::Expr)
    f.head == :const && return deconstruct_field(f.args[1])
    f.head == :(::) && return f.args[1], f.args[2]
    return nothing
end

macro construct(callexpr::Expr)
    callexpr = macroexpand(__module__, callexpr)
    isexpr(callexpr, :call) || error("`@construct` can only be applied to a function call")
    f, args = callexpr.args[1], callexpr.args[2:end]
    parameters = if !isempty(args) && isexpr(args[1], :parameters)
        popfirst!(args)
    else
        Expr(:parameters)
    end
    isempty(args) ?
        :($(esc(f))($Properties($parameters))) :
        :($(esc(f))($Properties($parameters), $(esc(args...))))
end

macro dynamic(expr::Expr)
    expr = macroexpand(__module__, expr)
    isexpr(expr, :struct) || error("`@dynamic` can only be applied to struct definitions")
    _, T, fieldsblock = expr.args
    if isexpr(T, :<:)
        T = T.args[1]
    end
    struct_name = uncurly(T)

    Base.remove_linenums!(fieldsblock)
    fieldlines = deconstruct_field.(fieldsblock.args)
    has_other_things = any(isnothing, fieldlines)
    filter!(!isnothing, fieldlines)
    fields = first.(fieldlines)
    types = last.(fieldlines)

    if !has_other_things
        S = uncurly(T)
        asserts = [Expr(:(::), f, t) for (f,t) in zip(fields, types)]
        constructors = if S == T
            quote
                if !all(==(:Any), $types)
                    $S($(asserts...); kwargs...) =
                        new($Properties(; kwargs...), $(fields...))
                end
                $S($(fields...); kwargs...) =
                    new($Properties(; kwargs...), $(fields...))
            end
        else
            P = T.args[2:end]
            Q = Any[isexpr(U, :<:) ? U.args[1] : U for U in P]
            quote
                $S($(asserts...); kwargs...) where {$(Q...)} =
                    new{$(Q...)}($Properties(; kwargs...), $(fields...))
                $S{$(Q...)}($(fields...); kwargs...) where {$(Q...)} =
                    new{$(Q...)}($Properties(; kwargs...), $(fields...))
            end
        end
        push!(fieldsblock.args, constructors)
    end

    insert!(fieldsblock.args, 1, :($PROPERTIES_FIELD_NAME::$Properties))

    return quote
        $(esc(:($Base.@__doc__ $expr)))

        Base.hasproperty(x::$(esc(struct_name)), name::Symbol) =
            hasfield(typeof(x), name) || hasproperty(properties(x), name)

        Base.propertynames(x::$(esc(struct_name))) =
            (fieldnames(typeof(x))[2:end]..., propertynames(properties(x))...)

        Base.propertynames(x::$(esc(struct_name)), private::Bool) =
            private ? (fieldnames(typeof(x))..., propertynames(properties(x))...) : Base.propertynames(x)

        Base.getproperty(x::$(esc(struct_name)), name::Symbol) =
            hasfield(typeof(x), name) ? getfield(x, name) : getproperty(properties(x), name, x)

        Base.setproperty!(x::$(esc(struct_name)), name::Symbol, value) =
            hasfield(typeof(x), name) ? setfield!(x, name, value) : setproperty!(properties(x), name, value)

        Base.delete!(x::$(esc(struct_name)), name::Symbol) = (delete!(properties(x), name); x)

        function Base.hash(x::$(esc(struct_name)), h::UInt)
            p_hash = hasnoproperty(properties(x)) ? h : hash(propertydict(properties(x)), h)
            field_hash = foldr(hash, getfield(x, fieldname) for fieldname in fieldnames(typeof(x))[2:end]; init=p_hash)
            hash(typeof(x), field_hash)
        end

        function Base.:(==)(x::$(esc(struct_name)), y::$(esc(struct_name)))
            x_empty, y_empty = hasnoproperty(properties(x)), hasnoproperty(properties(y))
            x_empty != y_empty && return false
            !x_empty && !y_empty && propertydict(properties(x)) != propertydict(properties(y)) && return false
            !any(name -> getfield(x, name) != getfield(y, name), fieldnames(typeof(x))[2:end])
        end

        function $(:(DynamicStructs.isdynamictype))(T::Type{$(esc(struct_name))})
            @nospecialize T
            true
        end

        nothing
    end
end
