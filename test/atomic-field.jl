@testset "atomic field in mutable struct (julia ^1.7)" begin
    @dynamic mutable struct AtomicPerson
        name::String
        @atomic age::Int
    end

    p = AtomicPerson("Anton", 19)
    @test p.name == "Anton"
    @test p.age == 19
    @test_throws ConcurrencyViolationError @atomic p.name
    @test (@atomic p.age) == 19
    @test (@atomic p.age = 20) == 20
    @test (@atomic :sequentially_consistent p.age = 21) == 21
    @test (@atomic p.age + 1) == (21 => 22)
    @test (@atomic p.age) == 22 
end
