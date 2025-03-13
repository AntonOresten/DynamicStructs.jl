@testset "const field in mutable struct (julia ^1.8)" begin
    @dynamic mutable struct ConstPerson
        const name::String
    end

    p = ConstPerson("Ryan", age=45)
    @test isdynamictype(ConstPerson)
    @test isdynamic(p)
    @test p.age == 45
    @test_throws ErrorException p.name = "Rory"
end