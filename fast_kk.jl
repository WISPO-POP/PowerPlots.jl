Pkg.activate(".")

using PowerModels
using PowerPlots
# using LightGraphs
using OMEinsum
# using RecursiveArrayTools
# using NetworkLayout
# using NLopt

path = "C:/Users/noahx/Documents/PowerDev/pglib-opf/"
PowerModels.silence()

for case in ["pglib_opf_case14_ieee.m","pglib_opf_case118_ieee.m","pglib_opf_case500_tamu.m","pglib_opf_case1354_pegase.m"]
    println(case)
    pmg = PowerModelsGraph(PowerModels.parse_file("$(path)$(case)"))
    @time pos1 = PowerPlots.kamada_kawai(pmg)
    @time pos2 = PowerPlots.new_kamada_kawai(pmg)
    println("Same Layout: $(all(pos1 .≈  pos2))") # same result?
    println()
end
