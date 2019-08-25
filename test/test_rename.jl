
function test_renaming_queries(section, queries)
    @testset "$section" begin
        for (sel, res) in queries
            eval(:(@test s.rename(df, $sel...) == DataFrames.rename(df, $(res...))))
        end
    end
end

function test_renaming_queries_bang(section, queries)
    @testset "$section" begin
        for (sel, res) in queries
            eval(:(@test s.rename!(copy(df), $sel...) == DataFrames.rename(df, $(res...))))
        end
    end
end

# https://github.com/JuliaLang/julia/issues/25612
function test_renaming_queries_warn(section, queries)
    @testset "$section" begin
        for (query, msg) in queries
            (sel, res) = query
            eval(:(@test_logs (:warn, $msg) s.rename(df, $sel...)))
        end
    end
end

function test_renaming_queries_warn_bang(section, queries)
    @testset "$section" begin
        for (query, msg) in queries
            (sel, res) = query
            cp_df = copy(df)
            eval(:(@test_logs (:warn, $msg) s.rename!($cp_df, $sel...)))
            eval(:(@test $cp_df == df))
        end
    end
end

renaming_queries = [:(rest() => key_map(uppercase),) => [:a => :A, :b => :B, :c1 => :C1],
                    :(:a => :X,) => [:a => :X],
                    :(1:2 => [:X, :Y],) => [:a => :X, :b => :Y],
                    :(1:2 => key_map(uppercase),) => [:a => :A, :b => :B],
                    :(1 => key_prefix("A"), :b => key_suffix("B"),) => [:a => :Aa, :b => :bB],
                    :(:c1 => key_suffix("C"), not(:b) => key_suffix("D"),) => [:c1 => :c1CD, :a => :aD]]

renaming_queries_warn = [
    (query = :(:a => [:X, :Y],) => [:a => :a],
     msg = "Renaming array had different length (2) than target selections (1), renaming skipped."),
    (query = :(1:2 => :X,) => [:a => :a, :b => :b],
     msg = "Renaming to a sigle new name is not supported for multiple selections (2), renaming skipped.")
]


@testset "rename" begin
    test_renaming_queries("Renaming", renaming_queries)
    test_renaming_queries_warn("Warnings", renaming_queries_warn)
end

@testset "rename!" begin
    test_renaming_queries_bang("Renaming", renaming_queries)
    test_renaming_queries_warn_bang("Warnings", renaming_queries_warn)
end
