
function test_renaming_queries(section, queries)
    @testset "$section" begin
        @testset "queries" begin
            for (sel, res) in queries
                eval(:(@test s.rename(df, $sel...) == DataFrames.rename(df, $(res...))))
            end
        end
    end
end

function test_renaming_queries_bang(section, queries)
    @testset "$section" begin
        @testset "queries" begin
            for (sel, res) in queries
                eval(:(@test s.rename!(copy(df), $sel...) == DataFrames.rename(df, $(res...))))
            end
        end
    end
end

renaming_queries = [:(rest() => key_map(uppercase),) => [:a => :A, :b => :B, :c1 => :C1],
                    :(:a => :X,) => [:a => :X],
                    :(:a => [:X, :Y],) => [:a => :a],
                    :(1:2 => :X,) => [:a => :a, :b => :b],
                    :(1:2 => [:X, :Y],) => [:a => :X, :b => :Y],
                    :(1:2 => key_map(uppercase),) => [:a => :A, :b => :B],
                    :(1 => key_prefix("A"), :b => key_suffix("B"),) => [:a => :Aa, :b => :bB],
                    :(:c1 => key_suffix("C"), not(:b) => key_suffix("D"),) => [:c1 => :c1CD, :a => :aD]]

@testset "rename" begin
    test_renaming_queries("Renaming", renaming_queries)
end

@testset "rename!" begin
    test_renaming_queries_bang("Renaming", renaming_queries)
end
