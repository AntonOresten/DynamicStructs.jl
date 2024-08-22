@testset "v1.8.jl" begin

    @testset "const field in mutable (julia ^1.8)" begin
        @dynamic mutable struct ConstPerson
            const name::String
        end

        p = ConstPerson("Ryan", age=45)
        @test isdynamictype(ConstPerson)
        @test isdynamic(p)
        @test p.age == 45
    end

end