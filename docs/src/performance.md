```@meta
CurrentModule = DynamicStructs
```

# Performance

## Static fields

A comparison between accessing static *fields* of regular and dynamic structs shows that performance impact is minimal,
and the LLVM code of accessing fields of a dynamic struct is still "nice".

```@repl
using DynamicStructs, Chairmarks, InteractiveUtils

struct A
    x::Int
end

@dynamic struct B
    x::Int
end

a, b = A(1), B(1)

f(arg) = arg.x^2

@b f($a)

@b f($b)

@code_llvm f(a)

@code_llvm f(b)
```

## Dynamic properties

Dynamic structs build on the static fields of regular structs, essentially strapping on an `AbstractDict{Symbol,Any}`,
which gets accessed if the property is not a field. This flexibility makes for a convenient interface,
but is also inherently type-unstable, meaning they will perform similarly to a field of unspecified type.
The LLVM code generated from dynamic property access is however significantly longer.

```@repl
using DynamicStructs, Chairmarks

struct C
    x::Int
    y
end

@dynamic struct D
    x::Int
end

c, d = C(1, 2), D(1, y=2);

g(arg) = arg.y^2;

@b g($c)

@b g($d)
```

## Tips

### Type assertions for type stability and improved performance

```@repl
using DynamicStructs, Chairmarks

@dynamic mutable struct A
    x::Int
end

v = [A(i, y=i) for i in 1:100];

@b sum(a.x for a in $v)

@b sum(a.y for a in $v)

@b sum(a.y::Int for a in $v)
```

### Function barriers help... sometimes

We observe that in one scenario, broadcasted addition of short vectors is 2x faster with a function barrier,
but 2x slower for longer vectors. This happens also with `Any`-typed fields of regular structs.

```@repl
using DynamicStructs, Chairmarks

@dynamic struct A end

f(a, b) = a.x .+ a.x;

g(x1, x2) = x1 .+ x2;

f_barrier(a, b) = g(a.x, b.x);

a, b = A(x = rand(1)), A(x = rand(1));

@b f($a, $b)

@b f_barrier($a, $b)

a, b = a, b = A(x = rand(10000)), A(x = rand(10000));

@b f($a, $b)

@b f_barrier($a, $b)
```
