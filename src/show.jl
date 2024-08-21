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

function showdynamic(io::IO, x::T) where T
    print(io, "$T(")
    public_fields = fieldnames(T)[1:end-1]
    for (i, fieldname) in enumerate(public_fields)
        print(io, repr(getfield(x, fieldname)))
        i < length(public_fields) && print(io, ", ")
    end
    isempty(getproperties(x; fields=false)) || print(io, "; ")
    for (i, (name, value)) in enumerate(property_dict(x))
        print(io, name, "=", repr(value))
        i < length(property_dict(x)) && print(io, ", ")
    end
    print(io, ")")
end

function showdynamic_pretty(io::IO, x::T; indent=2) where T
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
