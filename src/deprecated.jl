export @has, @get, @get!, @del!

@deprecate var"@del" var"@del!"

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

"""
    @get x.name default

Get the value of the property `:name` of `x`, or `default` if `x` has no such property.
Meant to act like the `get` function for collections.
Equivalent to `(@has x.name) ? x.name : default`.
"""
macro get(expr::Expr, default)
    expr isa Expr && expr.head == :. || throw(ArgumentError("Expression must be of the form `x.name`"))
    x, name = expr.args
    return :(Base.hasproperty($(esc(x)), $(esc(name))) ? $(esc(expr)) : $(esc(default)))
end

"""
    @get! x.name default

Get the value of the property `:name` of `x`, or `default` if `x` has no such property,
and set the property to `default`.
"""
macro get!(expr::Expr, default)
    expr isa Expr && expr.head == :. || throw(ArgumentError("Expression must be of the form `x.name`"))
    x, name = expr.args
    return quote
        if Base.hasproperty($(esc(x)), $(esc(name)))
            $(esc(expr))
        else
            Base.setproperty!($(esc(x)), $(esc(name)), $(esc(default)))
            $(esc(default))
        end
    end
end

delproperty!(x, name::Symbol) = (delete!(property_dict(x), name); x)

"""
    @del! x.name

Delete the dynamic property `:name` from dynamic type `x`. 
Equivalent to `DynamicStructs.delproperty!(x, :name)`.
"""
macro del!(expr::Expr)
    expr isa Expr && expr.head == :. || throw(ArgumentError("Expression must be of the form `x.name`"))
    x, name = expr.args
    return :(delproperty!($(esc(x)), $name))
end