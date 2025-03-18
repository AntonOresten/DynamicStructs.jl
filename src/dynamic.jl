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

function deconstruct_field(f)
    f isa Symbol && return f, :Any
    Meta.isexpr(f, (:const, :atomic)) && return deconstruct_field(f.args[1])
    Meta.isexpr(f, :(::)) && return f.args[1], f.args[2]
    return nothing
end

function showdynamic(io::IO, @nospecialize x)
    show(io, typeof(x))
    print(io, "(")
    fieldvals = propertyvalues(x, OnlyFields)
    for (i, val) in enumerate(fieldvals)
        show(io, val)
        i < length(fieldvals) && print(io, ", ")
    end
    for (i, (prop, val)) in enumerate(propertypairs(x, NoFields))
        print(io, isone(i) ? "; " : ", ")
        print(io, prop, " = ")
        show(io, val)
    end
    print(io, ")")
end

_hasproperty(x, name::Symbol) = hasfield(typeof(x), name) || hasproperty(properties(x), name)
_propertynames(x) = (fieldnames(typeof(x))[2:end]..., propertynames(properties(x))...)
_propertynames(x, private::Bool) = private ? (fieldnames(typeof(x))..., propertynames(properties(x))...) : Base.propertynames(x)
_getproperty(x, name::Symbol) = hasfield(typeof(x), name) ? getfield(x, name) : getproperty(properties(x), name, x)
_setproperty!(x, name::Symbol, value) = hasfield(typeof(x), name) ? setfield!(x, name, value) : setproperty!(properties(x), name, value)
_delete!(x, name::Symbol) = (delete!(properties(x), name); x)

function _hash(x, h::UInt)
    p_hash = hasnoproperty(properties(x)) ? h : hash(propertydict(properties(x)), h)
    field_hash = foldr(hash, getfield(x, fieldname) for fieldname in fieldnames(typeof(x))[2:end]; init=p_hash)
    hash(typeof(x), field_hash)
end

function _isequal(x, y)
    x_empty, y_empty = hasnoproperty(properties(x)), hasnoproperty(properties(y))
    x_empty != y_empty && return false
    !x_empty && !y_empty && propertydict(properties(x)) != propertydict(properties(y)) && return false
    !any(name -> getfield(x, name) != getfield(y, name), fieldnames(typeof(x))[2:end])
end


"""
    @dynamic [mutable] struct ... end

Define a dynamic struct:

- Instances of dynamic structs have dynamic properties that can be added/deleted at runtime.
  These properties are similar to `Any`-typed fields of structs in terms of performance.

- Fields remain statically typed and accessing them compiles similarly to structs,
  so performance should not be significantly affected.

- The macro adds a hidden field for storing dynamic properties with lazy initialization,
  meaning that the underlying storage is not allocated until the first dynamic property is added.

- The default constructors of dynamic structs accept keyword arguments for dynamic properties,
  with a `Base.show` method that reflects this.
  These are only present if the block is free of any non-field expressions, such as custom constructors.
"""
macro dynamic(expr::Expr)
    expr = macroexpand(__module__, expr)
    Meta.isexpr(expr, :struct) || error("`@dynamic` can only be applied to struct definitions")
    _, T, fieldsblock = expr.args
    T = Meta.isexpr(T, :<:) ? T.args[1] : T
    struct_name = Meta.isexpr(T, :curly) ? T.args[1] : T

    fieldlines = deconstruct_field.(Base.remove_linenums!(copy(fieldsblock)).args)

    if !any(isnothing, fieldlines)
        fields = first.(fieldlines)
        types = last.(fieldlines)
        asserts = [Expr(:(::), f, t) for (f,t) in zip(fields, types)]
        constructors = if !Meta.isexpr(T, :curly)
            quote
                if !all(==(:Any), $types)
                    $struct_name($(asserts...); kwargs...) =
                        new($Properties(; kwargs...), $(fields...))
                end
                $struct_name($(fields...); kwargs...) =
                    new($Properties(; kwargs...), $(fields...))
            end
        else
            P = T.args[2:end]
            Q = Any[Meta.isexpr(U, :<:) ? U.args[1] : U for U in P]
            quote
                $struct_name($(asserts...); kwargs...) where {$(Q...)} =
                    new{$(Q...)}($Properties(; kwargs...), $(fields...))
                $struct_name{$(Q...)}($(fields...); kwargs...) where {$(Q...)} =
                    new{$(Q...)}($Properties(; kwargs...), $(fields...))
            end
        end
        insert!(fieldsblock.args, 1, constructors)
        insert!(fieldsblock.args, 1, quote
            Base.show(io::IO, x::$struct_name) = $showdynamic(io, x)
        end)
    end

    insert!(fieldsblock.args, 1, :($PROPERTIES_FIELD_NAME::$Properties))

    dynamic_methods = quote
        Base.hasproperty(x::$struct_name, name::Symbol) = $_hasproperty(x, name)
        Base.propertynames(x::$struct_name) = $_propertynames(x)
        Base.propertynames(x::$struct_name, private::Bool) = $_propertynames(x, private)
        Base.getproperty(x::$struct_name, name::Symbol) = $_getproperty(x, name)
        Base.setproperty!(x::$struct_name, name::Symbol, value) = $_setproperty!(x, name, value)
        Base.delete!(x::$struct_name, name::Symbol) = $_delete!(x, name)
        Base.hash(x::$struct_name, h::UInt) = $_hash(x, h)
        Base.:(==)(x::$struct_name, y::$struct_name) = $_isequal(x, y)

        function $(:(DynamicStructs.isdynamictype))(T::Type{$struct_name})
            @nospecialize T
            true
        end
    end

    insert!(fieldsblock.args, 1, dynamic_methods)

    quote
        $(esc(:($Base.@__doc__ $expr)))
        $nothing
    end
end
