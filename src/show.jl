truncate(s::AbstractString, len::Integer) = length(s) > len ? String(first(s, len-1) * '…') : s

function printfield(io::IO, name::Symbol, value; showtype=true, indent=0)
    print(io, "\n", " "^indent)
    printstyled(io, string(name); color=:white)
    showtype && printstyled(io, "::"; color=:red)
    showtype && printstyled(io, replace(string(typeof(value)), " " => ""); color=:blue)
    printstyled(io, " = "; color=:red)
    printstyled(io, truncate(repr(value; context=io), 100))
end

function showdynamic(io::IO, x::T; indent=2) where T
    context = IOContext(io, :compact => true, :limit => true)

    print(context, summary(x), ":")

    fields = fieldnames(T)[1:end-1]
    n = length(fields)
    printstyled(context, "\n", " "^indent, iszero(n) ? "no" : n, " ", isone(n) ? "field" : "fields", ":", color=:yellow)
    for name in fieldnames(T)[1:end-1]
        printfield(context, name, getproperty(x, name); indent=2indent)
    end

    properties = keys(get_properties(x))
    n = length(properties)
    printstyled(context, "\n", " "^indent, iszero(n) ? "no" : n, " ", isone(n) ? "property" : "properties", ":", color=:yellow)
    for name in properties
        printfield(context, name, getproperty(x, name); indent=2indent)
    end
end
