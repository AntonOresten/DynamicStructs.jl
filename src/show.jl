# TODO: optimize handling of long field value representations
minimize(str::AbstractString, threshold::Integer) = length(str) > threshold ? "<exceeds max length>" : str

function printfield(io::IO, name::Symbol, value; showtype=true, indent=0)
    print(io, "\n", " "^indent)
    printstyled(io, string(name); color=:white)
    showtype && printstyled(io, "::"; color=:red)
    showtype && printstyled(io, replace(string(typeof(value)), " " => ""); color=:blue)
    printstyled(io, " = "; color=:red)
    printstyled(io, minimize(repr(value; context=io), 80))
end

"""
    showdynamic(io::IO, x::T) where T

Prints a representation of an instance `x`, parseable only if `T` is a dynamic type.

A dynamic struct `D` created with `@dynamic` will by default define a `Base.show(io::IO, x::D)` method to call this function.
"""
function showdynamic(io::IO, x::T) where T
    properties = getproperties(x, fields=false)
    fields = setdiff(getproperties(x, fields=true), properties)

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
    show_fields_properties(io::IO, x::T; private=false, indent=2) where T

Prints a human-readable representation of an instance `x`.

A dynamic struct `D` created with `@dynamic` will by default define a `Base.show(io::IO, ::MIME"text/plain", x::D)` method to call this function.

`private` determines whether private fields and properties are included in the output.
"""
function show_fields_properties(io::IO, x::T; private=false, indent=2) where T
    context = IOContext(io, :compact => true, :limit => true)

    properties = getproperties(x; fields=false, private)
    fields = setdiff(getproperties(x; fields=true, private), properties)

    print(context, summary(x), ":")

    printstyled(context, "\n", " "^indent, isempty(fields) ? "no" : length(fields), " ", isone(length(fields)) ? "field" : "fields", ":", color=:yellow)
    for name in fields
        printfield(context, name, getproperty(x, name); indent=2indent)
    end

    printstyled(context, "\n", " "^indent, isempty(properties) ? "no" : length(properties), " ", isone(length(properties)) ? "property" : "properties", ":", color=:yellow)
    for name in properties
        printfield(context, name, getproperty(x, name); indent=2indent)
    end
end
