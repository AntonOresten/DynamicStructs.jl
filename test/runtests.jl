using DynamicStructs
using Test

@testset "DynamicStructs.jl" begin

    @dynamic struct Person
        name::String
        age::Int
    end

    @testset "Default constructor" begin
        p = Person("Sackarias", 16, Properties(; sport="Tennis"))
        @test p.name == "Sackarias"
        @test p.age == 16
        @test p.sport == "Tennis"
    end

    @testset "Basic Functionality" begin
        p = Person("Alice", 30)
        @test p.name == "Alice"
        @test p.age == 30
        
        p.job = "Engineer"
        @test p.job == "Engineer"
        @test p._properties.job == "Engineer"
        @test get_properties(p).job == "Engineer"
        
        @test propertynames(p) == (:name, :age, :job)
        @test propertynames(p, true) == (:name, :age, :_properties, :job)
    end

    @testset "Constructor with Keywords" begin
        p = Person("Bob", 25, hobby="reading")
        @test p.name == "Bob"
        @test p.age == 25
        @test p.hobby == "reading"
    end

    @testset "Deletion" begin
        p = Person("Charlie", 40, temporary=true)
        @test hasproperty(p, :temporary)
        delete!(p, :temporary)
        @test !hasproperty(p, :temporary)
    end

    @testset "Error Handling" begin
        p = Person("David", 35)
        @test_throws ErrorException p.nonexistent
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
        
        # Test that we can't modify the name field
        @test_throws ErrorException p.name = "George"
        
        # But we can still add new properties
        p.job = "Teacher"
        @test p.job == "Teacher"
    end

    @testset "Properties Struct" begin
        props = Properties(a=1, b="two")
        @test props.a == 1
        @test props[:b] == "two"
        @test length(props) == 2
        @test collect(keys(props)) == [:a, :b]
        @test collect(values(props)) == [1, "two"]
    end
end
