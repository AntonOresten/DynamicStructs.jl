using DynamicStructs
using Documenter

DocMeta.setdocmeta!(
    DynamicStructs,
    :DocTestSetup,
    :(using DynamicStructs);
    recursive=true,
)

makedocs(;
    modules=[DynamicStructs],
    authors="Anton Oresten <antonoresten@gmail.com> and contributors",
    sitename="DynamicStructs.jl",
    format=Documenter.HTML(;
        canonical="https://antonoresten.github.io/DynamicStructs.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
    doctest=true,
)

deploydocs(;
    repo="github.com/AntonOresten/DynamicStructs.jl",
    devbranch="main",
)
