using DynamicStructs
using Test

@testset "DynamicStructs.jl" begin

    @dynamic struct Person
        name::String
        age::Int
    end

    @testset "property utilities" begin
        p = Person("Neil", 66, occupation="Besserwisser")

        @test propertynames(p, NoFields) == (:occupation,)
        @test propertynames(p, OnlyFields) == (:name, :age)
        @test propertynames(p, OnlyFields, true) == (DynamicStructs.PROPERTIES_FIELD_NAME, :name, :age)

        @test propertyvalues(p, NoFields) == ("Besserwisser",)
        @test propertyvalues(p, OnlyFields) == ("Neil", 66)

        @test propertypairs(p, NoFields) == (:occupation => "Besserwisser",)
        @test propertypairs(p, OnlyFields) == (:name => "Neil", :age => 66)

        # deprecated
        @test propertynames(p, NoFields()) == propertynames(p, NoFields)
        @test propertynames(p, OnlyFields()) == propertynames(p, OnlyFields)
        @test propertynames(p, OnlyFields(), true) == propertynames(p, OnlyFields, true)
    end

    @testset "Properties" begin
        p = DynamicStructs.Properties(a = 1, b = 2, c = 3)
        @test repr(p) == "DynamicStructs.Properties(a = 1, b = 2, c = 3)"
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
        @test str == "Person(\"Jacob\", 19; instrument = \"guitar\")"
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

    @testset "Generic Types" begin
        @dynamic struct GenericPerson{T}
            id::T
        end

        p = GenericPerson("ID001", nickname="Dave")
        @test p.id == "ID001"
        @test p.nickname == "Dave"
        @test GenericPerson{String}("ID001", nickname="Dave") == p
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

        VERSION ≥ v"1.7" && include("atomic-field.jl")
        VERSION ≥ v"1.8" && include("const-field.jl")
    end

    @testset "built-in constructors" begin
        @dynamic struct BuiltinPerson
            name::String
            0 # detected as non-field, removing dynamic constructor
        end

        p = BuiltinPerson(DynamicStructs.Properties(age=25), "John")
        @test p.name == "John"
        @test p.age == 25
    end

end
