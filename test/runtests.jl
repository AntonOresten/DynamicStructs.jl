using DynamicStructs
using Test

@testset "DynamicStructs.jl" begin

    @dynamic struct Person
        name::String
        age::Int
    end

    @testset "Default constructor" begin
        p = Person("Sackarias", 16, sport="Tennis")
        @test p.name == "Sackarias"
        @test p.age == 16
        @test p.sport == "Tennis"
    end

    @testset "isdynamictype and isdynamic" begin
        @test isdynamictype(Person)
        @test !isdynamictype(Int)
        @test !isdynamictype(Person("Sackarias", 16))
        @test isdynamic(Person("Sackarias", 16))
        @test !isdynamic(16)
        @test !isdynamic(Person)
    end

    @testset "Show" begin
        p = Person("Jacob", 19, instrument="guitar")
        str = sprint(show, p)
        @test str == "Person(\"Jacob\", 19; instrument=\"guitar\")"
        str_pretty = sprint(show, MIME("text/plain"), p)
        @test str_pretty == "Person:\n  2 fields:\n    name::String = \"Jacob\"\n    age::Int64 = 19\n  1 property:\n    instrument::String = \"guitar\""
    end

    @testset "Hash" begin
        @dynamic struct Vec
            x::Int
        end

        @test hash(Vec(0)) == hash(Vec(0))
        @test hash(Vec(0)) != hash(Vec(1))
        @test hash(Vec(0)) != hash(Vec(0, y=1))
        @test hash(Vec(0, y=1)) == hash(Vec(0, y=1))
        @test hash(Vec(0, y=1)) != hash(Vec(1, y=1))
        @test hash(Vec(0, y=1)) != hash(Vec(0, y=0))
        @test hash(Vec(0, y=1)) != hash(Vec(0, y=1, z=2))
    end

    @testset "Basic Functionality" begin
        p = Person("Alice", 30)
        @test p.name == "Alice"
        @test p.age == 30
        
        p.job = "Engineer"
        @test p.job == "Engineer"
        @test getproperties(p) == (:name, :age, :job)
        @test getproperties(p, private=true) == (:name, :age, :_dynamic_properties, :job)
        @test getproperties(p, fields=false) == (:job,)
        @test getproperties(p, fields=false, private=true) == (:job,)
    end

    @testset "Constructor with Keywords" begin
        p = Person("Bob", 25, hobby="reading")
        @test p.name == "Bob"
        @test p.age == 25
        @test p.hobby == "reading"
    end

    @testset "Base.delete!" begin
        p = Person("Elizabeth", 96)
        p.job = "Retired"
        @test delete!(p, :job) == p
        @test !hasproperty(p, :job)
    end

    # Deprecated
    @testset "Convenience macros" begin
        p = Person("Charlie", 40, temporary=true)
        @test (@get p.name "noname") == "Charlie"
        @test (@get p.nickname "nonickname") == "nonickname" 
        @test @has p.temporary
        @test (@get p.temporary false) == true
        @del! p.temporary
        @test !@has p.temporary
        @test (@get p.temporary false) == false

        @test @isdefined var"@del"
    end

    @testset "Error Handling" begin
        p = Person("David", 35)
        @test_throws ErrorException p.nonexistent
    end

    @testset "Untyped fields" begin
        @dynamic struct UntypedPerson
            name
            age
        end

        p = UntypedPerson("Eva", 45, job="Doctor")
        @test p.name == "Eva"
        @test p.age == 45
        @test p.job == "Doctor"
    end

    @testset "Disordered definition" begin
        @dynamic struct DisorderedPerson
            name::String

            DisorderedPerson() = DisorderedPerson("John", 25, job="Teacher")

            age::Int
        end

        p = DisorderedPerson()
        @test p == DisorderedPerson("John", 25, job="Teacher")
        @test getproperties(p) == (:name, :age, :job)
    end

    @testset "Generic Types" begin
        @dynamic struct GenericPerson{T}
            id::T
        end

        p = GenericPerson{String}("ID001", nickname="Dave")
        @test p.id == "ID001"
        @test p.nickname == "Dave"
    end

    @testset "Inheritance" begin
        abstract type AbstractEmployee end
        
        @dynamic struct Employee <: AbstractEmployee
            name::String
            position::String
        end

        e = Employee("Eve", "Manager", department="Sales")
        @test e isa AbstractEmployee
        @test e.name == "Eve"
        @test e.position == "Manager"
        @test e.department == "Sales"
    end

    @testset "Immutable Structs" begin
        @dynamic struct ImmutablePerson
            name::String
        end

        p = ImmutablePerson("Frank", age=50)
        @test p.name == "Frank"
        @test p.age == 50

        @test_throws ErrorException p.name = "George"

        p.job = "Teacher"
        @test p.job == "Teacher"
    end

    @testset "Mutable Structs" begin
        @dynamic mutable struct MutablePerson
            name::String
        end

        p = MutablePerson("Franco", age=35)
        @test p.name == "Franco"
        @test p.age == 35

        p.name = "Francisco"
        @test p.name == "Francisco"

        p.job = "General"
        @test p.job == "General"

        VERSION ≥ v"1.8" && include("const-field.jl")
    end

    @testset "Custom constructor" begin
        @dynamic struct Point{T}
            x::T
            y::T

            Point() = Point(1, 1)
            Point{T}() where T = Point{T}(1, 1)
        end

        @test Point() == Point{Int}(1, 1)
        @test Point{Float64}() == Point(1.0, 1.0)
    end
end
