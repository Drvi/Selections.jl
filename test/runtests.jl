import DataFrames
import Tables
import JuliaDB
import TypedTables
using Test

# push!(LOAD_PATH, "./src")
using Selections
const s = Selections

function _select_subset(tab, sub)
    t = NamedTuple{s.ensure_tuple(sub)}(Tables.columntable(tab))
    Tables.materializer(tab)(t)
end

function _select_rename(tab, renames)
    from = s.ensure_tuple(first.(renames))
    to = s.ensure_tuple(last.(renames))
    t = values(NamedTuple{from}(Tables.columntable(tab)))
    Tables.materializer(tab)(NamedTuple{to, typeof(t)}(t))
end

_pull(tab, col) = getproperty(tab, col)
_pull(tab::JuliaDB.IndexedTable, col) = JuliaDB.select(tab, col)

const df = DataFrames.DataFrame(a = 1:4, b = 'a':'d', c1 = [[float(i)] for i in 1:4])
const jdb = JuliaDB.table(df)
const tt = TypedTables.FlexTable(jdb)

@testset "Selections" begin
    include("test_select.jl")
end
