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

    properties = getproperties(x, fields=false)
    fields = setdiff(getproperties(x, fields=true), properties)

    printstyled(context, "\n", " "^indent, isempty(fields) ? "no" : length(fields), " ", isone(length(fields)) ? "field" : "fields", ":", color=:yellow)
    for name in fields
        printfield(context, name, getproperty(x, name); indent=2indent)
    end

    printstyled(context, "\n", " "^indent, isempty(properties) ? "no" : length(properties), " ", isone(length(properties)) ? "property" : "properties", ":", color=:yellow)
    for name in properties
        printfield(context, name, getproperty(x, name); indent=2indent)
    end
end
