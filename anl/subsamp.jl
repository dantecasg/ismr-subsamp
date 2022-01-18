# --------------------------------------------------------------------------- #
# Subsampling analysis
#
# Author: Dante T. Castro Garro
# Date: 2022-01-18
# --------------------------------------------------------------------------- #

# =========================================================================== #
# LIBRARIES
# =========================================================================== #

using NCDatasets
using DataFrames
using CSV
using Statistics
using Plots
using ColorSchemes
using Dates

# =========================================================================== #
# FUNCTIONS
# =========================================================================== #

include("../src/funcs_stat.jl")

# --------------------------------------------------------------------------- #

# Calculates the ensemble mean precipitation
function memMean(tbl, name)
    sel = tbl[tbl[:,name], [:tiempo, :pre]]
    grp = groupby(sel, :tiempo)
    smr = combine(grp, :pre => mean)

    res = DataFrame(tiempo = tiempo, pre = NaN)
    tiempo_sel = tiempo .∈ [smr[:,:tiempo] |> collect]
    res[tiempo_sel,"pre"] .= smr[:,"pre_mean"]
    return res
end

# --------------------------------------------------------------------------- #
# Subsampling functions

# Phase subsampling
function subPhase(mem, ref)
    if ref < 0
        sel_pha = mem .< 0
    else
        sel_pha = mem .>= 0
    end
    return sel_pha
end

# Subsampling of the "n" closest members
function subClose(mem, ref; n = 10)
    dist = abs.(mem .- ref)
    orde = sortperm(dist)
    res = repeat([false], size(mem, 1))
    res[orde[1:n]] .= true
    return res
end

# Subsampling by majority
function subMaj(mem)
    mem_tf = mem .>= 0
    eval = sum(mem_tf)
    if eval >=  15
        sel_maj = mem_tf
    else
        sel_maj = .!(mem_tf)
    end
    return sel_maj
end

# --------------------------------------------------------------------------- #
# Plotting functions

# Comparison between indeces
function indexComp(; obs, mem, tit)
    # Ensemble mean
    ens = groupby(mem, :year)
    ens = combine(ens, :nor => mean => :ens)
    ens = ens.ens
    # Correlation
    corr = corNaN(obs, ens)
    corr = round(corr, digits = 2) |> string
    # Plot
    scatter(
        tiempo_d,
        mem.nor,
        markercolor = "brown",
        markersize = 2,
        markerstrokewidht = 0,
        markeralpha = 0.2,
        label = "Members")
    plot!(
        tiempo,
        obs,
        linecolor = "black",
        linewidth = 2,
        label = "Observed")
    plot!(
        tiempo,
        ens,
        linecolor = "brown",
        linewidth = 2,
        label = "Ensemble mean")
    annotate!(
        1982,
        3,
        text("Correlation: " * corr, :left, 10))
    hline!([0], linecolor = "gray", label = "")
    ylims!((-4,4))

    title!(tit)
    plot!(legend = false)
end

# Plot of the subsampling
function subsamPlot(; pre = pre_obs, tiempo = tiempo, mem, name, tit, lgd = false)
    sub = memMean(mem, name)
    corr = corNaN(sub[:,"pre"] |> collect, pre)
    corr = round(corr, digits = 2)

    g_sub = scatter(
        mem[.!mem[:,name],"tiempo"],
        mem[.!mem[:,name],"pre"],
        label = "Not selected",
        markercolor = "royalblue",
        markersize = 2,
        markerstrokewidth = 0,
        markeralpha = 0.4)
    scatter!(
        mem[mem[:,name],"tiempo"],
        mem[mem[:,name],"pre"],
        label = "Selected", 
        markercolor = "brown",
        markersize = 2.5,
        markerstrokewidth = 0,
        markeralpha = 0.5)
    plot!(
        tiempo,
        pre,
        label = "Observed",
        linecolor = "black",
        lw = 2)
    plot!(
        sub[:,"tiempo"],
        sub[:,"pre"],
        label = "Ensemble mean",
        linecolor = "brown",
        linewidth = 2)
    hline!([0], linecolor = "gray", label = "")
    annotate!(1982, 2, text("Corr: " * string(corr), :left, 10))
    plot!(legend = lgd)
    ylims!((-2.5, 2.5))
    ylabel!("mm/day")
    title!(tit)

    return g_sub
end

# --------------------------------------------------------------------------- #

# Loads indexes value
function loadIndex(idx)
    # Opening files
    if idx == "oni"
        obs_fil = datapath * "index/" * idx * "-obs_1982-2021-mon.csv"
    else
        obs_fil = datapath * "index/" * idx * "-obs_1981-2016-mon.csv"
    end
    asm_fil = datapath * "index/" * idx * "-asm_1981-2016-mon.csv"
    mem_fil = datapath * "index/" * idx * "-mem_1981-2016-mon.csv"

    obs = CSV.File(obs_fil) |> DataFrame
    asm = CSV.File(asm_fil) |> DataFrame
    mem = CSV.File(mem_fil) |> DataFrame

    # Getting months for data
    if idx == "amm"
        obs = transform(obs, 
            :time => (x -> month.(x)) => :month,
            :time => (x -> year.(x)) => :year,
            :amm => :idx)
        asm = transform(asm, :time => (x -> Date.(SubString.(x, 1, 10))) => :time)
        asm = transform(asm,
            :time => (x -> month.(x)) => :month,
            :time => (x -> year.(x)) => :year,
            :amm => :idx)
        mem = transform(mem, :time => (x -> Date.(SubString.(x, 1, 10))) => :time)
        mem = transform(mem,
            :time => (x -> month.(x)) => :month,
            :time => (x -> year.(x)) => :year,
            :ens => :member,
            :amm => :idx)
    end

    # Extracting a specific month or 3-month mean
    if idx == "oni"
        obs = obs[obs.year .<= 2016,:]
        obs = obs[obs.month .== 7,:]
        asm = asm[asm.month .== 7,:]
        mem = mem[mem.month .== 7,:]
    else
        obs = obs[6 .<= obs.month .<= 8,:]
        obs = groupby(obs, :year)
        obs = combine(obs, :idx => mean => :idx)

        asm = asm[6 .<= asm.month .<= 8,:]
        asm = groupby(asm, :year)
        asm = combine(asm, :idx => mean => :idx)

        mem = mem[6 .<= mem.month .<= 8,:]
        mem = groupby(mem, [:member, :year])
        mem = combine(mem, :idx => mean => :idx)
    end

    # Normalizing data
    obs = normalize(obs.idx)
    asm = normalize(asm.idx)
    mem = groupby(mem, :member)
    mem = combine(mem, :year, :idx => (x -> normalize(x)) => :nor)

    return obs, asm, mem
end

# =========================================================================== #
# PROCESS
# =========================================================================== #

datapath = "../data/"
tiempo = 1981:2016
tiempo_d = repeat(tiempo, 30)
nyear = size(tiempo, 1)

# --------------------------------------------------------------------------- #
# Loading data

# Precipitation data
pre_obs_nc = Dataset(datapath * "prec/gpcp-obs_pre_1981-2016-JJAS_ts.nc")
pre_obs = pre_obs_nc["precip"]
pre_obs = pre_obs .- mean(pre_obs[1:30])

pre_mem_nc = Dataset(datapath * "prec/mpi-echam-ens_pre_1981-2016-JJAS_ts.nc")
pre_mem_old = pre_mem_nc["precip"]

pre_mem = zeros(size(pre_mem_old))
for i in 1:size(pre_mem_old,1)
    pre_mem[i,:] = pre_mem_old[i,:] .- mean(pre_mem_old[i,1:30])
end

pre_mem_d = vec(pre_mem')
pre_ens = mean(pre_mem, dims = 1) |> vec

# ONI
oni_obs_nor, oni_asm_nor, oni_mem = loadIndex("oni")
oni_obs_nor = [NaN; oni_obs_nor]

# The other indexes
dmi_obs_nor, dmi_asm_nor, dmi_mem = loadIndex("dmi")
wio_obs_nor, wio_asm_nor, wio_mem = loadIndex("wio")
wyi_obs_nor, wyi_asm_nor, wyi_mem = loadIndex("wyi")
amm_obs_nor, amm_asm_nor, amm_mem = loadIndex("amm")


# --------------------------------------------------------------------------- #
# Index performance

g_oni = indexComp(
    obs = oni_obs_nor,
    mem = oni_mem,
    tit = "Normalized ONI")

g_dmi = indexComp(
    obs = dmi_obs_nor,
    mem = dmi_mem,
    tit = "Normalized DMI")

g_wio = indexComp(
    obs = wio_obs_nor,
    mem = wio_mem,
    tit = "Normalized WIO")

g_wyi = indexComp(
    obs  = wyi_obs_nor,
    mem  = wyi_mem,
    tit = "Normalized WYI")

g_amm = indexComp(
    obs  = amm_obs_nor,
    mem  = amm_mem,
    tit = "Normalized AMM")

l_index = @layout[a b c; d{0.31w} e{0.31w}]
g_index = plot(
    g_oni,
    g_dmi,
    g_wio,
    g_wyi,
    g_amm,
    layout = l_index)
plot!(dpi = 300, size = (1200,700))
savefig(g_index, "../img/subsamp/index_nor_comp.png")

# --------------------------------------------------------------------------- #
# Subsampling

# ........................................................................... #
# Perfect precipitation prediction

sel = 0:29
per_pre_sel = DataFrame(
    tiempo = tiempo_d,
    pre = pre_mem_d,
    sel = false)

for i in 1:nyear
    sel_pre = subClose(pre_mem[:,i], pre_obs[i], n = 10)
    per_pre_sel[sel[sel_pre] .* 36 .+ i,"sel"] .= true
end

g_per_pre = subsamPlot(
    mem = per_pre_sel,
    name = "sel",
    tit = "Perfect precipitation subsampling",
    lgd = :outerbottom)
savefig(g_per_pre, "../img/subsamp/prec_perfect.png")

# ........................................................................... #
# Phase matching

pre_mem_sel_pha = DataFrame(
    tiempo = tiempo_d, 
    pre = pre_mem_d,
    oni = false,
    dmi = false,
    wio = false,
    wyi = false,
    amm = false,
    cmb = false,
    all = true)

for i in 1:nyear
    sel_pha_oni = subPhase(oni_mem[oni_mem.year .== tiempo[i],"nor"], oni_asm_nor[i])
    sel_pha_dmi = subPhase(dmi_mem[dmi_mem.year .== tiempo[i],"nor"], dmi_asm_nor[i])
    sel_pha_wio = subPhase(wio_mem[wio_mem.year .== tiempo[i],"nor"], wio_asm_nor[i])
    sel_pha_wyi = subPhase(wyi_mem[wyi_mem.year .== tiempo[i],"nor"], wyi_asm_nor[i])
    sel_pha_amm = subPhase(amm_mem[amm_mem.year .== tiempo[i],"nor"], amm_asm_nor[i])

    # Combining
    sel_pha_bth = sel_pha_oni .& sel_pha_wio

    # Allocating in table
    pre_mem_sel_pha[sel[sel_pha_oni] .* 36 .+ i,"oni"] .= true
    pre_mem_sel_pha[sel[sel_pha_wio] .* 36 .+ i,"wio"] .= true
    pre_mem_sel_pha[sel[sel_pha_dmi] .* 36 .+ i,"dmi"] .= true
    pre_mem_sel_pha[sel[sel_pha_wyi] .* 36 .+ i,"wyi"] .= true
    pre_mem_sel_pha[sel[sel_pha_amm] .* 36 .+ i,"amm"] .= true
    pre_mem_sel_pha[sel[sel_pha_bth] .* 36 .+ i,"cmb"] .= true
end

# Plots
g_sub_ens = subsamPlot(
    mem = pre_mem_sel_pha,
    name = "all",
    tit = "Ensemble mean",
    lgd = false)
savefig(g_sub_ens, "../img/subsamp/pre_sub_mean.png")

g_sub_pha_idx = []
idx_pha = ["oni", "dmi", "wio", "wyi", "amm", "cmb"]
for i in idx_pha
    g = subsamPlot(
        mem = pre_mem_sel_pha,
        name = i,
        tit = i == "cmb" ? "ONI & WIO" : uppercase(i),
        lgd = false)
    push!(g_sub_pha_idx, g)
end

l_sub_pha = @layout[a b c; d e f]
g_sub_pha = plot(
    g_sub_pha_idx[1],
    g_sub_pha_idx[2],
    g_sub_pha_idx[3],
    g_sub_pha_idx[4],
    g_sub_pha_idx[5],
    g_sub_pha_idx[6],
    layout = l_sub_pha)
plot!(dpi = 300, size = (1200,700))
savefig(g_sub_pha, "../img/subsamp/prec_sub_pha.png")

# ........................................................................... #
# 10 Closest members

nclo = 10
pre_mem_sel_clo = DataFrame(
    tiempo = tiempo_d,
    pre = pre_mem_d,
    oni = false,
    dmi = false,
    wio = false,
    wyi = false,
    amm = false,
    cmb = false,
    all = true)

for i in 1:nyear
    sel_clo_oni = subClose(oni_mem[oni_mem.year .== tiempo[i],"nor"], oni_asm_nor[i], n = nclo)
    sel_clo_dmi = subClose(dmi_mem[dmi_mem.year .== tiempo[i],"nor"], dmi_asm_nor[i], n = nclo)
    sel_clo_wio = subClose(wio_mem[wio_mem.year .== tiempo[i],"nor"], wio_asm_nor[i], n = nclo)
    sel_clo_wyi = subClose(wyi_mem[wyi_mem.year .== tiempo[i],"nor"], wyi_asm_nor[i], n = nclo)
    sel_clo_amm = subClose(amm_mem[amm_mem.year .== tiempo[i],"nor"], amm_asm_nor[i], n = nclo)

    # Combining
    sel_clo_all = sel_clo_oni .& sel_clo_wyi # 10 sel

    # Allocating in table
    pre_mem_sel_clo[sel[sel_clo_oni] .* 36 .+ i,"oni"] .= true
    pre_mem_sel_clo[sel[sel_clo_dmi] .* 36 .+ i,"dmi"] .= true
    pre_mem_sel_clo[sel[sel_clo_wio] .* 36 .+ i,"wio"] .= true
    pre_mem_sel_clo[sel[sel_clo_wyi] .* 36 .+ i,"wyi"] .= true
    pre_mem_sel_clo[sel[sel_clo_amm] .* 36 .+ i,"amm"] .= true
    pre_mem_sel_clo[sel[sel_clo_all] .* 36 .+ i,"cmb"] .= true
end

g_sub_clo_idx = []
idx_clo = ["oni", "dmi", "wio", "wyi", "amm", "cmb"]
for i in idx_clo
    g = subsamPlot(
        mem = pre_mem_sel_clo,
        name = i,
        tit = i == "cmb" ? "ONI & WYI" : uppercase(i),
        lgd = false)
    push!(g_sub_clo_idx, g)
end

l_sub_clo = @layout[a b c; d e f]
g_sub_clo = plot(
    g_sub_clo_idx[1],
    g_sub_clo_idx[2],
    g_sub_clo_idx[3],
    g_sub_clo_idx[4],
    g_sub_clo_idx[5],
    g_sub_clo_idx[6],
    layout = l_sub_clo)
plot!(dpi = 300, size = (1200,700))
savefig(g_sub_clo, "../img/subsamp/prec_sub_clo.png")

# ........................................................................... #
# Combining subsamplings

# Creating table
pre_mem_sel_eli = DataFrame(
    tiempo = tiempo_d,
    pre = pre_mem_d,
    oni = false,
    dmi = false,
    wio = false,
    wyi = false,
    amm = false,
    cmb = false,
    all = true)

first_sel = 10
secon_sel = 5
for i in 1:nyear
    fil_eli = subClose(wyi_mem[wyi_mem.year .== tiempo[i],"nor"], wyi_asm_nor[i], n = first_sel)

    oni_mem_fil = copy(oni_mem[oni_mem.year .== tiempo[i],"nor"])
    dmi_mem_fil = copy(dmi_mem[dmi_mem.year .== tiempo[i],"nor"])
    wio_mem_fil = copy(wio_mem[wio_mem.year .== tiempo[i],"nor"])
    wyi_mem_fil = copy(wyi_mem[wyi_mem.year .== tiempo[i],"nor"])
    amm_mem_fil = copy(amm_mem[amm_mem.year .== tiempo[i],"nor"])
    # hack
    oni_mem_fil[.!fil_eli] .= -999
    dmi_mem_fil[.!fil_eli] .= -999 
    wio_mem_fil[.!fil_eli] .= -999
    wyi_mem_fil[.!fil_eli] .= -999
    amm_mem_fil[.!fil_eli] .= -999

    sel_eli_oni = subClose(oni_mem_fil, oni_asm_nor[i], n = secon_sel)
    sel_eli_dmi = subClose(dmi_mem_fil, dmi_asm_nor[i], n = secon_sel)
    sel_eli_wio = subClose(wio_mem_fil, wio_asm_nor[i], n = secon_sel)
    sel_eli_wyi = subClose(wyi_mem_fil, wyi_asm_nor[i], n = secon_sel)
    sel_eli_amm = subClose(amm_mem_fil, amm_asm_nor[i], n = secon_sel)

    pre_mem_sel_eli[sel[sel_eli_oni] .* 36 .+ i,"oni"] .= true
    pre_mem_sel_eli[sel[sel_eli_dmi] .* 36 .+ i,"dmi"] .= true
    pre_mem_sel_eli[sel[sel_eli_wio] .* 36 .+ i,"wio"] .= true
    pre_mem_sel_eli[sel[sel_eli_wyi] .* 36 .+ i,"wyi"] .= true
    pre_mem_sel_eli[sel[sel_eli_amm] .* 36 .+ i,"amm"] .= true
end

g_sub_eli_idx = []
idx_eli = ["oni", "dmi", "wio", "wyi", "amm"]
for i in idx_eli
    g = subsamPlot(
        mem = pre_mem_sel_eli,
        name = i,
        tit = uppercase(i),
        lgd = i == "amm" ? :outerright : false)
    push!(g_sub_eli_idx, g)
end

l_sub_eli = @layout[a b c; d{0.31w} e{0.47w}]
g_sub_eli = plot(
    g_sub_eli_idx[1],
    g_sub_eli_idx[2],
    g_sub_eli_idx[3],
    g_sub_eli_idx[4],
    g_sub_eli_idx[5],
    layout = l_sub_eli)
plot!(dpi = 300, size = (1200,700))
savefig(g_sub_eli, "../img/subsamp/prec_sub_eli.png")

# ........................................................................... #
# Niño events grouping

nclon = 10
ninoy = [1982,1983,1985,1987,1988,
    1989,1991,1992,1995,1996,1997,
    1998,1999,2000,2006,2008,2009,
    2010,2011,2012,2015,2016] # At least 3 months from DJF to JJA
ninon = setdiff(tiempo, ninoy)
sel_ninoy = indexin(ninoy, tiempo)
sel_ninon = indexin(ninon, tiempo)

pre_mem_sel_nin = DataFrame(
    tiempo = tiempo_d,
    pre = pre_mem_d,
    oni = false,
    dmi = false,
    wio = false,
    wyi = false,
    amm = false,
    all = true)

# Only for El Niño/a years
for i in sel_ninoy
    sel_nin_oni = subClose(oni_mem[oni_mem.year .== tiempo[i],"nor"], oni_asm_nor[i], n = nclo)

    # Allocating in table
    pre_mem_sel_nin[sel[sel_nin_oni] .* 36 .+ i,"oni"] .= true
    pre_mem_sel_nin[sel[sel_nin_oni] .* 36 .+ i,"dmi"] .= true
    pre_mem_sel_nin[sel[sel_nin_oni] .* 36 .+ i,"wio"] .= true
    pre_mem_sel_nin[sel[sel_nin_oni] .* 36 .+ i,"wyi"] .= true
    pre_mem_sel_nin[sel[sel_nin_oni] .* 36 .+ i,"amm"] .= true
end

# Neutral years
for i in sel_ninon
    sel_nin_oni = subClose(oni_mem[oni_mem.year .== tiempo[i],"nor"], oni_asm_nor[i], n = nclo)
    sel_nin_dmi = subClose(dmi_mem[dmi_mem.year .== tiempo[i],"nor"], dmi_asm_nor[i], n = nclo)
    sel_nin_wio = subClose(wio_mem[wio_mem.year .== tiempo[i],"nor"], wio_asm_nor[i], n = nclo)
    sel_nin_wyi = subClose(wyi_mem[wyi_mem.year .== tiempo[i],"nor"], wyi_asm_nor[i], n = nclo)
    sel_nin_amm = subClose(amm_mem[amm_mem.year .== tiempo[i],"nor"], amm_asm_nor[i], n = nclo)

    # Allocating in table
    pre_mem_sel_nin[sel[sel_nin_oni] .* 36 .+ i,"oni"] .= true
    pre_mem_sel_nin[sel[sel_nin_dmi] .* 36 .+ i,"dmi"] .= true
    pre_mem_sel_nin[sel[sel_nin_wio] .* 36 .+ i,"wio"] .= true
    pre_mem_sel_nin[sel[sel_nin_wyi] .* 36 .+ i,"wyi"] .= true
    pre_mem_sel_nin[sel[sel_nin_amm] .* 36 .+ i,"amm"] .= true
end

g_sub_nin_idx = []
idx_nin = ["oni", "dmi", "wio", "wyi", "amm"]
for i in idx_nin
    g = subsamPlot(
        mem = pre_mem_sel_nin,
        name = i,
        tit = uppercase(i),
        lgd = i == "amm" ? :outerright : false)
    push!(g_sub_nin_idx, g)
end

l_sub_nin = @layout[a b c; d{0.31w} e{0.47w}]
g_sub_nin = plot(
    g_sub_nin_idx[1],
    g_sub_nin_idx[2],
    g_sub_nin_idx[3],
    g_sub_nin_idx[4],
    g_sub_nin_idx[5],
    layout = l_sub_nin)
plot!(dpi = 300, size = (1200,700))
savefig(g_sub_nin, "../img/subsamp/prec_sub_nin.png")

# ........................................................................... #
# Majority selection

pre_mem_sel_maj = DataFrame(
    tiempo = tiempo_d,
    pre = pre_mem_d,
    oni = false,
    dmi = false,
    wio = false,
    wyi = false,
    amm = false,
    all = true)

for i in 1:nyear
    sel_maj_oni = subMaj(oni_mem[oni_mem.year .== tiempo[i],"nor"])
    sel_maj_dmi = subMaj(dmi_mem[dmi_mem.year .== tiempo[i],"nor"])
    sel_maj_wio = subMaj(wio_mem[wio_mem.year .== tiempo[i],"nor"])
    sel_maj_wyi = subMaj(wyi_mem[wyi_mem.year .== tiempo[i],"nor"])
    sel_maj_amm = subMaj(amm_mem[amm_mem.year .== tiempo[i],"nor"])

    # Allocating in table
    pre_mem_sel_maj[sel[sel_maj_oni] .* 36 .+ i,"oni"] .= true
    pre_mem_sel_maj[sel[sel_maj_dmi] .* 36 .+ i,"dmi"] .= true
    pre_mem_sel_maj[sel[sel_maj_wio] .* 36 .+ i,"wio"] .= true
    pre_mem_sel_maj[sel[sel_maj_wyi] .* 36 .+ i,"wyi"] .= true
    pre_mem_sel_maj[sel[sel_maj_amm] .* 36 .+ i,"amm"] .= true
end

g_sub_maj_idx = []
idx_maj = ["oni", "dmi", "wio", "wyi", "amm"]
for i in idx_maj
    g = subsamPlot(
        mem = pre_mem_sel_maj,
        name = i,
        tit = uppercase(i),
        lgd = i == "amm" ? :outerright : false)
    push!(g_sub_maj_idx, g)
end

l_sub_maj = @layout[a b c; d{0.31w} e{0.47w}]
g_sub_maj = plot(
    g_sub_maj_idx[1],
    g_sub_maj_idx[2],
    g_sub_maj_idx[3],
    g_sub_maj_idx[4],
    g_sub_maj_idx[5],
    layout = l_sub_maj)
plot!(dpi = 300, size = (1200,700))
savefig(g_sub_maj, "../img/subsamp/prec_sub_maj.png")
