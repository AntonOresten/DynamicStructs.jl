```@meta
CurrentModule = DynamicStructs
```

# Performance

## Static fields

A comparison between accessing static *fields* of regular and dynamic structs shows that performance impact is minimal,
and the LLVM code of accessing fields of a dynamic struct is still "nice".

```@repl performance
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

```@repl performance
struct C
    x::Int
    y
end

b, c = B(1, y=2), b(1, 2);

g(arg) = arg.y^2;

@b g($b)

@b g($c)
```

## Tips

### Type assertions for type stability and improved performance

```@repl performance
v = [B(i, y=i) for i in 1:100];

@b sum(b.x for b in $v)

@b sum(b.y for b in $v)

@b sum(b.y::Int for b in $v)
```

### Function barriers help... sometimes

We observe that in one scenario, broadcasted addition of short vectors is 2x faster with a function barrier,
but 2x slower for longer vectors. This happens also with `Any`-typed fields of regular structs.

```@repl performance
@dynamic struct D end

f(a, b) = a.x .+ a.x;

g(x1, x2) = x1 .+ x2;

f_barrier(a, b) = g(a.x, b.x);

a, b = D(x = rand(1)), D(x = rand(1));

@b f($a, $b)

@b f_barrier($a, $b)

a, b = D(x = rand(10000)), D(x = rand(10000));

@b f($a, $b)

@b f_barrier($a, $b)
```
