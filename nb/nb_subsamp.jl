### A Pluto.jl notebook ###
# v0.17.1

using Markdown
using InteractiveUtils

# ╔═╡ 68534a0f-d37f-4dc3-b16f-845de7a3616a
using NCDatasets

# ╔═╡ 413e150c-41de-4eaf-a9fe-297408e97039
using DataFrames

# ╔═╡ 58066b35-ce6c-41e3-a055-de025099cbba
using CSV

# ╔═╡ 777efcd0-c3e2-40c2-a225-4067fad3ffed
using Statistics

# ╔═╡ 57d1bf70-02c2-416c-bcf9-71fee1e5db16
using Plots

# ╔═╡ deb04563-40f4-4f3b-81dd-aca722946e06
using ColorSchemes

# ╔═╡ d720dc13-06e4-43e6-ac90-1f59ee628d1f
using Dates

# ╔═╡ e4f5d63f-6f33-41b3-acb1-83e43cb48a41
include("../src/funcs_stat.jl");

# ╔═╡ dd7d8178-f9a5-11eb-3166-3bf64f8a5b94
md"""
# Sub sampling and comparisons

## Libraries
"""

# ╔═╡ 4a933403-1159-4499-9da2-21806a7e9118
md"## Functions"

# ╔═╡ 0414004d-92c5-4c11-a66e-c787cf770f4f
md"""
### Predefine functions

`funcs_stat.jl`:

- normalize -> normalize a time series

- corNaN -> corraltion considering NaN values

- runMean -> running mean of a time series
"""

# ╔═╡ eb573962-b209-4947-ac4a-2157716c8230
md" ### Subsampling"

# ╔═╡ 20a4022c-e6a6-4b27-8f79-64553aa85e14
function subPhase(mem, ref)
	if ref < 0
		sel_pha = mem .< 0
	else
		sel_pha = mem .>= 0
	end
	return sel_pha
end

# ╔═╡ 332007c6-361d-47f3-858a-6efec64a0956
function subClose(mem, ref; n = 10)
	dist = abs.(mem .- ref)
	orde = sortperm(dist)
	res = repeat([false], size(mem, 1))
	res[orde[1:n]] .= true
	return res
end

# ╔═╡ 2a9f5c29-a0e3-4b12-be8f-b633b8ba134d
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

# ╔═╡ d7887f87-9870-4d93-919d-a997fffece92
md" ### Plots"

# ╔═╡ 9119a97d-3066-41fd-b0ec-ba251273de9a
md"""
### Loading data
"""

# ╔═╡ 44e159ca-926c-493c-a632-fae40f53bc13
md"""
## General parameters
"""

# ╔═╡ aaff210f-6978-4e6f-8282-a73eda938456
datapath = "../data/";

# ╔═╡ 936712ef-6c1d-481e-8fdc-45947c10c4c3
# Loads index values for DMI, WIO and WYI
# as a reference, check the code for ONI
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

# ╔═╡ 3f72d620-687a-4196-a018-83a4829fdb55
# Time
begin
	tiempo = 1981:2016
	tiempo_d = repeat(tiempo, 30)
	nyear = size(tiempo, 1)
end;

# ╔═╡ 7a3a7850-db85-4076-9ea7-3e6f808cd215
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

# ╔═╡ 2c865a00-f0e0-4f5d-83b1-53634a0e98be
# Comparison between indeces
function indexComp(; obs, mem, tit, scale = true)
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
	
	if scale
		hline!([0], linecolor = "gray", label = "")
		ylims!((-4,4))
	end
	
	title!(tit)
	plot!(legend = false)
end

# ╔═╡ 46921293-4fbb-4f90-aae0-16a1eae61264
md"""
## Data
"""

# ╔═╡ 7077dfb9-d106-4289-9edc-d1f766628a36
md"""
### Precipitation
"""

# ╔═╡ 3e528c81-1d6d-42ef-925b-400e42683ca2
# Precipitation - GPCP
begin
	pre_obs_nc = Dataset(datapath * "prec/gpcp-obs_pre_1981-2016-JJAS_ts.nc")
	pre_obs = pre_obs_nc["precip"]	
	pre_obs = pre_obs .- mean(pre_obs[1:30])
end;

# ╔═╡ 1863af7b-570a-4daf-9aaf-b937aa242678
function subsamPlot2(;pre = pre_obs, tiempo = tiempo, mem, name, tit, lgd = false)
	sub = memMean(mem, name)
	corr = corNaN(sub[:,"pre"] |> collect, pre)
	corr = round(corr, digits = 2)
	
	g_sub = scatter(
		mem[mem[:,name],"tiempo"],
		mem[mem[:,name],"pre"],
		label = "Members", 
		markercolor = "brown",
		alpha = 0.1)
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
	annotate!(1982, 2, text("r = " * string(corr), :left, 10))
	plot!(legend = lgd)
	ylims!((-2.5, 2.5))
	ylabel!("mm/day")
	title!(tit)
	
	return g_sub
end

# ╔═╡ e88b7e6d-8312-4484-8310-56acb1afbe5b
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

# ╔═╡ 88df45e1-4f2f-41f0-892a-09dfc4f3805d
# Precipitation - Members
begin
	pre_mem_nc = Dataset(datapath * "prec/mpi-echam-ens_pre_1981-2016-JJAS_ts.nc")
	pre_mem_old = pre_mem_nc["precip"]
	
	pre_mem = zeros(size(pre_mem_old))
	for i in 1:size(pre_mem_old,1)
		pre_mem[i,:] = pre_mem_old[i,:] .- mean(pre_mem_old[i,1:30])
	end
	
	pre_mem_d = vec(pre_mem')
	pre_ens = mean(pre_mem, dims = 1) |> vec 
end;

# ╔═╡ 796443d5-2bcb-4333-99fc-6a3b86df8c0f
md"""
### ONI
"""

# ╔═╡ bdcdad87-25e9-4590-ae8c-94acefd7c435
begin
	oni_obs_nor, oni_asm_nor, oni_mem = loadIndex("oni")
	oni_obs_nor = [NaN; oni_obs_nor]
end;

# ╔═╡ 81a8cc1e-c841-4de1-9b39-69af9393a8ca
md"""
### DMI
"""

# ╔═╡ aae51c1f-e24d-4380-a87f-8f31bfbe41ca
dmi_obs_nor, dmi_asm_nor, dmi_mem = loadIndex("dmi");

# ╔═╡ 9dea6e5e-ea3e-4620-9ed2-9d5f0ee6b843
md"""
### Western Indian Ocean (WIO)
"""

# ╔═╡ 2277a30e-63a9-49b9-bbc4-9c47510ed4c8
wio_obs_nor, wio_asm_nor, wio_mem = loadIndex("wio");

# ╔═╡ 27f1eccc-6580-4198-a45e-8d31e306cf6e
md"""
### Webster-Yang Index
"""

# ╔═╡ d9595ed6-f743-4f4d-b66c-fcb447f800c2
wyi_obs_nor, wyi_asm_nor, wyi_mem = loadIndex("wyi");

# ╔═╡ c844d780-e3e1-4680-9496-6bdd2382c951
md"""
### Atlantic Meridional Mode (AMM)
"""

# ╔═╡ 120378a8-1c97-47b6-b485-5b061d1ecb59
amm_obs_nor, amm_asm_nor, amm_mem = loadIndex("amm");

# ╔═╡ 93299161-ffad-4a2d-9892-19d94c41434a
md"""
### Index performance
"""

# ╔═╡ e3e77cc2-64ad-4105-b2aa-4607b2fc3025
g_oni = indexComp(
	obs = oni_obs_nor,
	mem = oni_mem,
	tit = "Normalized ONI");

# ╔═╡ db4980a0-a510-4187-b110-6638b71aeb8a
g_dmi = indexComp(
	obs = dmi_obs_nor,
	mem = dmi_mem,
	tit = "Normalized DMI");

# ╔═╡ 1f8aa5d9-7a16-4087-8ca8-377bf651e442
g_wio = indexComp(
	obs = wio_obs_nor,
	mem = wio_mem,
	tit = "Normalized WIO");

# ╔═╡ 69781e69-1a2b-464b-b032-5c50908cd89d
g_wyi = indexComp(
	obs  = wyi_obs_nor,
	mem  = wyi_mem,
	tit = "Normalized WYI",
	scale = true);

# ╔═╡ 528e9905-dfb0-43ac-b732-7d3e28416e4c
g_amm = indexComp(
	obs  = amm_obs_nor,
	mem  = amm_mem,
	tit = "Normalized AMM",
	scale = true);

# ╔═╡ 32ced8ae-ce39-4c0d-a70d-54a97d92a8b5
begin
	#l_index = @layout[a b; c d]
	l_index = @layout[a b c; d{0.31w} e{0.31w}]
	g_index = plot(
		g_oni,
		g_dmi,
		g_wio,
		g_wyi,
		g_amm,
		layout = l_index)
	#plot!(dpi = 300, size = (800,500))
	plot!(dpi = 300, size = (1200,700))
end

# ╔═╡ e655822f-7c68-4252-a557-4ecd12dcc892
savefig(g_index, "../img/subsamp/index_nor_comp.png")

# ╔═╡ ea7eb11e-1070-4229-9f2d-809a7b1c5e7b
md"""
## Sub-sampling
"""

# ╔═╡ 1d2f62d7-88bf-4a34-88b7-94b9cee07b3f
md"""
### Perfect precipitation prediction
"""

# ╔═╡ bed521e1-7afa-4553-a004-fb3f45b66c1e
md" ### Phase matching"

# ╔═╡ e1e24b52-2f09-47c7-abcc-0f0588b83e1a
# Members mean with matches the phase
begin
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
	sel = 0:29
	
	for i in 1:nyear
		sel_pha_oni = subPhase(oni_mem[oni_mem.year .== tiempo[i],"nor"], oni_asm_nor[i])
		sel_pha_dmi = subPhase(dmi_mem[dmi_mem.year .== tiempo[i],"nor"], dmi_asm_nor[i])
		sel_pha_wio = subPhase(wio_mem[wio_mem.year .== tiempo[i],"nor"], wio_asm_nor[i])
		sel_pha_wyi = subPhase(wyi_mem[wyi_mem.year .== tiempo[i],"nor"], wyi_asm_nor[i])
		sel_pha_amm = subPhase(amm_mem[amm_mem.year .== tiempo[i],"nor"], amm_asm_nor[i])
	
		# Combining
		sel_pha_bth = sel_pha_oni .& sel_pha_wio
		#sel_pha_bth = sel_pha_oni .& sel_pha_wio .& sel_pha_dmi
		
		# Allocating in table
		pre_mem_sel_pha[sel[sel_pha_oni] .* 36 .+ i,"oni"] .= true
		pre_mem_sel_pha[sel[sel_pha_wio] .* 36 .+ i,"wio"] .= true
		pre_mem_sel_pha[sel[sel_pha_dmi] .* 36 .+ i,"dmi"] .= true
		pre_mem_sel_pha[sel[sel_pha_wyi] .* 36 .+ i,"wyi"] .= true
		pre_mem_sel_pha[sel[sel_pha_amm] .* 36 .+ i,"amm"] .= true
		pre_mem_sel_pha[sel[sel_pha_bth] .* 36 .+ i,"cmb"] .= true
	end
end;

# ╔═╡ 648a4b29-ac60-4cdc-9b32-7eec331fff9a
begin
	per_pre_sel = DataFrame(
		tiempo = tiempo_d,
		pre = pre_mem_d,
		sel = false)
	
	for i in 1:nyear
		sel_pre = subClose(pre_mem[:,i], pre_obs[i], n = 10)
		per_pre_sel[sel[sel_pre] .* 36 .+ i,"sel"] .= true
	end
end;

# ╔═╡ 3a005a47-4617-4e95-a45c-b2b71698e97a
g_per_pre = subsamPlot(
	mem = per_pre_sel,
	name = "sel",
	tit = "Perfect precipitation subsampling",
	lgd = :outerbottom)

# ╔═╡ 804909ab-e745-477a-9172-26ee4bbe09bb
# Plot
begin
	g_sub_ens = subsamPlot(
		mem = pre_mem_sel_pha,
		name = "all",
		tit = "Ensemble mean",
		lgd = false)
	g_sub_oni = subsamPlot(
		mem = pre_mem_sel_pha,
		name = "oni",
		tit = "ONI",
		lgd = false)
	g_sub_dmi = subsamPlot(
		mem = pre_mem_sel_pha,
		name = "dmi",
		tit = "DMI",
		lgd = false)
	g_sub_wio = subsamPlot(
		mem = pre_mem_sel_pha,
		name = "wio",
		tit = "WIO",
		lgd = false)
	g_sub_wyi = subsamPlot(
		mem = pre_mem_sel_pha,
		name = "wyi",
		tit = "WYI",
		lgd = false)
	g_sub_amm = subsamPlot(
		mem = pre_mem_sel_pha,
		name = "amm",
		tit = "AMM",
		lgd = false)
	g_sub_all = subsamPlot(
		mem = pre_mem_sel_pha,
		name = "cmb",
		tit = "ONI & WIO",
		lgd = false)
end;

# ╔═╡ 52ed2cab-64bb-476e-bc34-bb211ec6669a
g_sub_ens

# ╔═╡ 03b54197-d1ed-486d-bda4-5344b7cec738
# Plot
begin
	l_subsam = @layout[a b c; d e f]
	#l_subsam = @layout[a b c; d{0.31w} e{0.31w}]
	g_subsam = plot(
		#g_sub_ens,
		g_sub_oni,
		g_sub_dmi,
		g_sub_wio,
		g_sub_wyi,
		g_sub_amm,
		g_sub_all,
		layout = l_subsam)
	#title!("Anomalies of precipitation for JJAS")
	plot!(dpi = 300, size = (1200,700))
end

# ╔═╡ 594f826a-6a42-43de-a3a5-66b82c6d9b44
savefig(g_subsam, "../img/subsamp/prec_sub_pha.png")

# ╔═╡ c0b0a7e2-9bb9-4562-9971-777dc2b28202
md"""
### 10 closest
"""

# ╔═╡ 8758332b-532d-45f5-bb1a-9b568e76b569
# Members mean with indeces close to assimilation
begin
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
		#sel_clo_all = sel_clo_wio .| sel_clo_wyi # 5 sel
		#sel_clo_all = sel_clo_oni .& sel_clo_wio .& sel_clo_wyi .& sel_clo_dmi
		
		# Allocating in table
		pre_mem_sel_clo[sel[sel_clo_oni] .* 36 .+ i,"oni"] .= true
		pre_mem_sel_clo[sel[sel_clo_dmi] .* 36 .+ i,"dmi"] .= true
		pre_mem_sel_clo[sel[sel_clo_wio] .* 36 .+ i,"wio"] .= true
		pre_mem_sel_clo[sel[sel_clo_wyi] .* 36 .+ i,"wyi"] .= true
		pre_mem_sel_clo[sel[sel_clo_amm] .* 36 .+ i,"amm"] .= true
		pre_mem_sel_clo[sel[sel_clo_all] .* 36 .+ i,"cmb"] .= true
	end
end;

# ╔═╡ 9d37598f-4ae0-4e6b-a27d-542410eab3e0
# Plot
begin
	g_sub_oni_clo = subsamPlot(
		mem = pre_mem_sel_clo,
		name = "oni",
		tit = "ONI",
		lgd = false)
	g_sub_dmi_clo = subsamPlot(
		mem = pre_mem_sel_clo,
		name = "dmi",
		tit = "DMI",
		lgd = false)
	g_sub_wio_clo = subsamPlot(
		mem = pre_mem_sel_clo,
		name = "wio",
		tit  = "WIO",
		lgd = false)
	g_sub_wyi_clo = subsamPlot(
		mem = pre_mem_sel_clo,
		name = "wyi",
		tit = "WYI",
		lgd = false)
	g_sub_amm_clo = subsamPlot(
		mem = pre_mem_sel_clo,
		name = "amm",
		tit = "AMM",
		lgd = false)
	g_sub_all_clo = subsamPlot(
		mem = pre_mem_sel_clo,
		name = "cmb",
		tit = "ONI & WYI",
		lgd = false)
end;

# ╔═╡ 167b9732-ded5-4523-a8fd-e2daa5a4780c
# Plot
begin
	l_sub_clo = @layout[a b c; d e f]
	#l_sub_clo = @layout[a b c; d{0.31w} e{0.31w}]
	g_sub_clo = plot(
		#g_sub_ens,
		g_sub_oni_clo,
		g_sub_dmi_clo,
		g_sub_wio_clo,
		g_sub_wyi_clo,
		g_sub_amm_clo,
		g_sub_all_clo,
		layout = l_sub_clo)
	#title!("Anomalies of precipitation for JJAS")
	plot!(dpi = 300, size = (1200,700))
end

# ╔═╡ f329ef2b-2a6f-4a65-a191-84a10257b66e
savefig(g_sub_clo, "../img/subsamp/prec_sub_clo.png")

# ╔═╡ a6c40f6d-d747-4d54-b6f2-75bad19cd315
md"""
### Elimination system
"""

# ╔═╡ 705cd677-7a72-49e3-8964-a564dd872fdd
# Eliminating 10 memebers based on ONI
begin
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
end

# ╔═╡ ad79dad7-a9c0-4685-996e-67a51885c4f1
begin
	g_sub_eli_idx = []
	idx = ["oni", "dmi", "wio", "wyi", "amm"]
	for i in idx
		g = subsamPlot(
			mem = pre_mem_sel_eli,
			name = i,
			tit = uppercase(i),
			lgd = i == "amm" ? :outerright : false)
		push!(g_sub_eli_idx, g)
	end
end

# ╔═╡ e47cc9a8-8bed-49f9-917b-87f64f22cdd5
begin
	l_sub_eli = @layout[a b c; d{0.31w} e{0.47w}]
	#l_sub_eli = @layout[a b c; d e f]
	g_sub_eli = plot(
		#g_sub_ens,
		g_sub_eli_idx[1],
		g_sub_eli_idx[2],
		g_sub_eli_idx[3],
		g_sub_eli_idx[4],
		g_sub_eli_idx[5],
		layout = l_sub_eli)
	#title!("Anomalies of precipitation for JJAS")
	plot!(dpi = 300, size = (1200,700))
end

# ╔═╡ 8555e0d5-9fcb-4e69-b4be-d618554ed282
savefig(g_sub_eli, "../img/subsamp/prec_sub_eli.png")

# ╔═╡ 6eefbf0e-6530-4792-8359-edd97db29fbb
md"### Niño events grouping"

# ╔═╡ cbc110e3-a8ca-45e5-83fc-744f9156a67c
# Use ONI index for El Niño / La Niña years
begin
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
		#cmb = false,
		all = true)

	# Only for El Niño/a years
	for i in sel_ninoy
		sel_nin_oni = subClose(oni_mem[oni_mem.year .== tiempo[i],"nor"], oni_asm_nor[i], n = nclo)
		#sel_nin_dmi = subClose(dmi_mem[dmi_mem.year .== tiempo[i],"nor"], dmi_asm_nor[i], n = nclo)
		#sel_nin_wio = subClose(wio_mem[wio_mem.year .== tiempo[i],"nor"], wio_asm_nor[i], n = nclo)
		#sel_nin_wyi = subClose(wyi_mem[wyi_mem.year .== tiempo[i],"nor"], wyi_asm_nor[i], n = nclo)
		#sel_nin_amm = subClose(amm_mem[amm_mem.year .== tiempo[i],"nor"], amm_asm_nor[i], n = nclo)
	
		# Combining
		#sel_clo_all = sel_clo_oni .& sel_clo_wyi # 10 sel
		#sel_clo_all = sel_clo_wio .| sel_clo_wyi # 5 sel
		#sel_clo_all = sel_clo_oni .& sel_clo_wio .& sel_clo_wyi .& sel_clo_dmi
		
		# Allocating in table
		pre_mem_sel_nin[sel[sel_nin_oni] .* 36 .+ i,"oni"] .= true
		pre_mem_sel_nin[sel[sel_nin_oni] .* 36 .+ i,"dmi"] .= true
		pre_mem_sel_nin[sel[sel_nin_oni] .* 36 .+ i,"wio"] .= true
		pre_mem_sel_nin[sel[sel_nin_oni] .* 36 .+ i,"wyi"] .= true
		pre_mem_sel_nin[sel[sel_nin_oni] .* 36 .+ i,"amm"] .= true
		#pre_mem_sel_clo[sel[sel_clo_all] .* 36 .+ i,"cmb"] .= true
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
end;

# ╔═╡ 2c7424a9-eb78-41bd-a985-7fb83f94499c
begin
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
end

# ╔═╡ 063b4794-0c3f-4a1a-a484-ccc5d316d313
begin
	l_sub_nin = @layout[a b c; d{0.31w} e{0.47w}]
	#l_sub_nin = @layout[a b c; d e f]
	g_sub_nin = plot(
		#g_sub_ens,
		g_sub_nin_idx[1],
		g_sub_nin_idx[2],
		g_sub_nin_idx[3],
		g_sub_nin_idx[4],
		g_sub_nin_idx[5],
		layout = l_sub_nin)
	#title!("Anomalies of precipitation for JJAS")
	plot!(dpi = 300, size = (1200,700))
end

# ╔═╡ 8b831ccd-895a-416e-8c70-472c72896af8
savefig(g_sub_nin, "../img/subsamp/prec_sub_nin.png")

# ╔═╡ 976be02c-22f0-4333-b815-eaa999af6046
md"### Majority prediction"

# ╔═╡ fb9d2b6d-3274-4292-986e-3393bdc06df4
# Members mean with indeces close to assimilation
begin
	pre_mem_sel_maj = DataFrame(
		tiempo = tiempo_d,
		pre = pre_mem_d,
		oni = false,
		dmi = false,
		wio = false,
		wyi = false,
		amm = false,
		#cmb = false,
		all = true)
	
	for i in 1:nyear
		sel_maj_oni = subMaj(oni_mem[oni_mem.year .== tiempo[i],"nor"])
		sel_maj_dmi = subMaj(dmi_mem[dmi_mem.year .== tiempo[i],"nor"])
		sel_maj_wio = subMaj(wio_mem[wio_mem.year .== tiempo[i],"nor"])
		sel_maj_wyi = subMaj(wyi_mem[wyi_mem.year .== tiempo[i],"nor"])
		sel_maj_amm = subMaj(amm_mem[amm_mem.year .== tiempo[i],"nor"])
	
		# Combining
		#sel_clo_all = sel_clo_oni .& sel_clo_wyi # 10 sel
		#sel_clo_all = sel_clo_wio .| sel_clo_wyi # 5 sel
		#sel_clo_all = sel_clo_oni .& sel_clo_wio .& sel_clo_wyi .& sel_clo_dmi
		
		# Allocating in table
		pre_mem_sel_maj[sel[sel_maj_oni] .* 36 .+ i,"oni"] .= true
		pre_mem_sel_maj[sel[sel_maj_dmi] .* 36 .+ i,"dmi"] .= true
		pre_mem_sel_maj[sel[sel_maj_wio] .* 36 .+ i,"wio"] .= true
		pre_mem_sel_maj[sel[sel_maj_wyi] .* 36 .+ i,"wyi"] .= true
		pre_mem_sel_maj[sel[sel_maj_amm] .* 36 .+ i,"amm"] .= true
		#pre_mem_sel_clo[sel[sel_clo_all] .* 36 .+ i,"cmb"] .= true
	end
end;

# ╔═╡ 2fb0c711-2606-4913-8c1b-7e59d74b24d0
begin
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
end

# ╔═╡ 6d5a5c24-d401-4109-bb91-1d62fb1eae81
begin
	l_sub_maj = @layout[a b c; d{0.31w} e{0.47w}]
	g_sub_maj = plot(
		#g_sub_ens,
		g_sub_maj_idx[1],
		g_sub_maj_idx[2],
		g_sub_maj_idx[3],
		g_sub_maj_idx[4],
		g_sub_maj_idx[5],
		layout = l_sub_maj)
	#title!("Anomalies of precipitation for JJAS")
	plot!(dpi = 300, size = (1200,700))
end

# ╔═╡ 10a992bb-55dd-40e3-891e-95c53c12727e
savefig(g_sub_maj, "../img/subsamp/prec_sub_maj.png")

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
CSV = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
ColorSchemes = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
Dates = "ade2ca70-3891-5945-98fb-dc099432e06a"
NCDatasets = "85f8d34a-cbdd-5861-8df4-14fed0d494ab"
Plots = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[compat]
CSV = "~0.8.5"
ColorSchemes = "~3.13.0"
DataFrames = "~1.2.2"
NCDatasets = "~0.11.6"
Plots = "~1.20.0"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

[[Adapt]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "84918055d15b3114ede17ac6a7182f68870c16f7"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "3.3.1"

[[ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"

[[Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c3598e525718abcc440f69cc6d5f60dda0a1b61e"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.6+5"

[[CFTime]]
deps = ["Dates", "Printf"]
git-tree-sha1 = "bca6cb6ee746e6485ca4535f6cc29cf3579a0f20"
uuid = "179af706-886a-5703-950a-314cd64e0468"
version = "0.1.1"

[[CSV]]
deps = ["Dates", "Mmap", "Parsers", "PooledArrays", "SentinelArrays", "Tables", "Unicode"]
git-tree-sha1 = "b83aa3f513be680454437a0eee21001607e5d983"
uuid = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
version = "0.8.5"

[[Cairo_jll]]
deps = ["Artifacts", "Bzip2_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "JLLWrappers", "LZO_jll", "Libdl", "Pixman_jll", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "e2f47f6d8337369411569fd45ae5753ca10394c6"
uuid = "83423d85-b0ee-5818-9007-b63ccbeb887a"
version = "1.16.0+6"

[[ColorSchemes]]
deps = ["ColorTypes", "Colors", "FixedPointNumbers", "Random", "StaticArrays"]
git-tree-sha1 = "ed268efe58512df8c7e224d2e170afd76dd6a417"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.13.0"

[[ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "024fe24d83e4a5bf5fc80501a314ce0d1aa35597"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.0"

[[Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "417b0ed7b8b838aa6ca0a87aadf1bb9eb111ce40"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.12.8"

[[Compat]]
deps = ["Base64", "Dates", "DelimitedFiles", "Distributed", "InteractiveUtils", "LibGit2", "Libdl", "LinearAlgebra", "Markdown", "Mmap", "Pkg", "Printf", "REPL", "Random", "SHA", "Serialization", "SharedArrays", "Sockets", "SparseArrays", "Statistics", "Test", "UUIDs", "Unicode"]
git-tree-sha1 = "344f143fa0ec67e47917848795ab19c6a455f32c"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "3.32.0"

[[CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"

[[Contour]]
deps = ["StaticArrays"]
git-tree-sha1 = "9f02045d934dc030edad45944ea80dbd1f0ebea7"
uuid = "d38c429a-6771-53c6-b99e-75d170b6e991"
version = "0.5.7"

[[Crayons]]
git-tree-sha1 = "3f71217b538d7aaee0b69ab47d9b7724ca8afa0d"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.0.4"

[[DataAPI]]
git-tree-sha1 = "ee400abb2298bd13bfc3df1c412ed228061a2385"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.7.0"

[[DataFrames]]
deps = ["Compat", "DataAPI", "Future", "InvertedIndices", "IteratorInterfaceExtensions", "LinearAlgebra", "Markdown", "Missings", "PooledArrays", "PrettyTables", "Printf", "REPL", "Reexport", "SortingAlgorithms", "Statistics", "TableTraits", "Tables", "Unicode"]
git-tree-sha1 = "d785f42445b63fc86caa08bb9a9351008be9b765"
uuid = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
version = "1.2.2"

[[DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "7d9d316f04214f7efdbb6398d545446e246eff02"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.10"

[[DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[DelimitedFiles]]
deps = ["Mmap"]
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"

[[Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[Downloads]]
deps = ["ArgTools", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"

[[EarCut_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "92d8f9f208637e8d2d28c664051a00569c01493d"
uuid = "5ae413db-bbd1-5e63-b57d-d24a61df00f5"
version = "2.1.5+1"

[[Expat_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b3bfd02e98aedfa5cf885665493c5598c350cd2f"
uuid = "2e619515-83b5-522b-bb60-26c02a35a201"
version = "2.2.10+0"

[[FFMPEG]]
deps = ["FFMPEG_jll"]
git-tree-sha1 = "b57e3acbe22f8484b4b5ff66a7499717fe1a9cc8"
uuid = "c87230d0-a227-11e9-1b43-d7ebe4e7570a"
version = "0.4.1"

[[FFMPEG_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "JLLWrappers", "LAME_jll", "LibVPX_jll", "Libdl", "Ogg_jll", "OpenSSL_jll", "Opus_jll", "Pkg", "Zlib_jll", "libass_jll", "libfdk_aac_jll", "libvorbis_jll", "x264_jll", "x265_jll"]
git-tree-sha1 = "3cc57ad0a213808473eafef4845a74766242e05f"
uuid = "b22a6f82-2f65-5046-a5b2-351ab43fb4e5"
version = "4.3.1+4"

[[FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[Fontconfig_jll]]
deps = ["Artifacts", "Bzip2_jll", "Expat_jll", "FreeType2_jll", "JLLWrappers", "Libdl", "Libuuid_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "35895cf184ceaab11fd778b4590144034a167a2f"
uuid = "a3f928ae-7b40-5064-980b-68af3947d34b"
version = "2.13.1+14"

[[Formatting]]
deps = ["Printf"]
git-tree-sha1 = "8339d61043228fdd3eb658d86c926cb282ae72a8"
uuid = "59287772-0a20-5a39-b81b-1366585eb4c0"
version = "0.4.2"

[[FreeType2_jll]]
deps = ["Artifacts", "Bzip2_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "cbd58c9deb1d304f5a245a0b7eb841a2560cfec6"
uuid = "d7e528f0-a631-5988-bf34-fe36492bcfd7"
version = "2.10.1+5"

[[FriBidi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "aa31987c2ba8704e23c6c8ba8a4f769d5d7e4f91"
uuid = "559328eb-81f9-559d-9380-de523a88c83c"
version = "1.0.10+0"

[[Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[GLFW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libglvnd_jll", "Pkg", "Xorg_libXcursor_jll", "Xorg_libXi_jll", "Xorg_libXinerama_jll", "Xorg_libXrandr_jll"]
git-tree-sha1 = "0c603255764a1fa0b61752d2bec14cfbd18f7fe8"
uuid = "0656b61e-2033-5cc2-a64a-77c0f6c09b89"
version = "3.3.5+1"

[[GR]]
deps = ["Base64", "DelimitedFiles", "GR_jll", "HTTP", "JSON", "Libdl", "LinearAlgebra", "Pkg", "Printf", "Random", "Serialization", "Sockets", "Test", "UUIDs"]
git-tree-sha1 = "182da592436e287758ded5be6e32c406de3a2e47"
uuid = "28b8d3ca-fb5f-59d9-8090-bfdbd6d07a71"
version = "0.58.1"

[[GR_jll]]
deps = ["Artifacts", "Bzip2_jll", "Cairo_jll", "FFMPEG_jll", "Fontconfig_jll", "GLFW_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll", "Pixman_jll", "Pkg", "Qt5Base_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "d59e8320c2747553788e4fc42231489cc602fa50"
uuid = "d2c73de3-f751-5644-a686-071e5b155ba9"
version = "0.58.1+0"

[[GeometryBasics]]
deps = ["EarCut_jll", "IterTools", "LinearAlgebra", "StaticArrays", "StructArrays", "Tables"]
git-tree-sha1 = "58bcdf5ebc057b085e58d95c138725628dd7453c"
uuid = "5c1252a2-5f33-56bf-86c9-59e7332b4326"
version = "0.4.1"

[[Gettext_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "9b02998aba7bf074d14de89f9d37ca24a1a0b046"
uuid = "78b55507-aeef-58d4-861c-77aaff3498b1"
version = "0.21.0+0"

[[Glib_jll]]
deps = ["Artifacts", "Gettext_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Libiconv_jll", "Libmount_jll", "PCRE_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "a32d672ac2c967f3deb8a81d828afc739c838a06"
uuid = "7746bdde-850d-59dc-9ae8-88ece973131d"
version = "2.68.3+2"

[[Grisu]]
git-tree-sha1 = "53bb909d1151e57e2484c3d1b53e19552b887fb2"
uuid = "42e2da0e-8278-4e71-bc24-59509adca0fe"
version = "1.0.2"

[[HDF5_jll]]
deps = ["Artifacts", "JLLWrappers", "LibCURL_jll", "Libdl", "OpenSSL_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "fd83fa0bde42e01952757f01149dd968c06c4dba"
uuid = "0234f1f7-429e-5d53-9886-15a909be8d59"
version = "1.12.0+1"

[[HTTP]]
deps = ["Base64", "Dates", "IniFile", "Logging", "MbedTLS", "NetworkOptions", "Sockets", "URIs"]
git-tree-sha1 = "44e3b40da000eab4ccb1aecdc4801c040026aeb5"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "0.9.13"

[[IniFile]]
deps = ["Test"]
git-tree-sha1 = "098e4d2c533924c921f9f9847274f2ad89e018b8"
uuid = "83e8ac13-25f8-5344-8a64-a9f2b223428f"
version = "0.5.0"

[[InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[InvertedIndices]]
deps = ["Test"]
git-tree-sha1 = "15732c475062348b0165684ffe28e85ea8396afc"
uuid = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
version = "1.0.0"

[[IterTools]]
git-tree-sha1 = "05110a2ab1fc5f932622ffea2a003221f4782c18"
uuid = "c8e1da08-722c-5040-9ed9-7db0dc04731e"
version = "1.3.0"

[[IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[JLLWrappers]]
deps = ["Preferences"]
git-tree-sha1 = "642a199af8b68253517b80bd3bfd17eb4e84df6e"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.3.0"

[[JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "8076680b162ada2a031f707ac7b4953e30667a37"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.2"

[[JpegTurbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "d735490ac75c5cb9f1b00d8b5509c11984dc6943"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "2.1.0+0"

[[LAME_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "f6250b16881adf048549549fba48b1161acdac8c"
uuid = "c1c5ebd0-6772-5130-a774-d5fcae4a789d"
version = "3.100.1+0"

[[LZO_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e5b909bcf985c5e2605737d2ce278ed791b89be6"
uuid = "dd4b983a-f0e5-5f8d-a1b7-129d4a5fb1ac"
version = "2.10.1+0"

[[LaTeXStrings]]
git-tree-sha1 = "c7f1c695e06c01b95a67f0cd1d34994f3e7db104"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.2.1"

[[Latexify]]
deps = ["Formatting", "InteractiveUtils", "LaTeXStrings", "MacroTools", "Markdown", "Printf", "Requires"]
git-tree-sha1 = "a4b12a1bd2ebade87891ab7e36fdbce582301a92"
uuid = "23fbe1c1-3f47-55db-b15f-69d7ec21a316"
version = "0.15.6"

[[LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"

[[LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"

[[LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"

[[LibVPX_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "12ee7e23fa4d18361e7c2cde8f8337d4c3101bc7"
uuid = "dd192d2f-8180-539f-9fb4-cc70b1dcf69a"
version = "1.10.0+0"

[[Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[Libffi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "0b4a5d71f3e5200a7dff793393e09dfc2d874290"
uuid = "e9f186c6-92d2-5b65-8a66-fee21dc1b490"
version = "3.2.2+1"

[[Libgcrypt_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgpg_error_jll", "Pkg"]
git-tree-sha1 = "64613c82a59c120435c067c2b809fc61cf5166ae"
uuid = "d4300ac3-e22c-5743-9152-c294e39db1e4"
version = "1.8.7+0"

[[Libglvnd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll", "Xorg_libXext_jll"]
git-tree-sha1 = "7739f837d6447403596a75d19ed01fd08d6f56bf"
uuid = "7e76a0d4-f3c7-5321-8279-8d96eeed0f29"
version = "1.3.0+3"

[[Libgpg_error_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c333716e46366857753e273ce6a69ee0945a6db9"
uuid = "7add5ba3-2f88-524e-9cd5-f83b8a55f7b8"
version = "1.42.0+0"

[[Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "42b62845d70a619f063a7da093d995ec8e15e778"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.16.1+1"

[[Libmount_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "9c30530bf0effd46e15e0fdcf2b8636e78cbbd73"
uuid = "4b2f31a3-9ecc-558c-b454-b3730dcb73e9"
version = "2.35.0+0"

[[Libtiff_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Pkg", "Zlib_jll", "Zstd_jll"]
git-tree-sha1 = "340e257aada13f95f98ee352d316c3bed37c8ab9"
uuid = "89763e89-9b03-5906-acba-b20f662cd828"
version = "4.3.0+0"

[[Libuuid_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "7f3efec06033682db852f8b3bc3c1d2b0a0ab066"
uuid = "38a345b3-de98-5d2b-a5d3-14cd9215e700"
version = "2.36.0+0"

[[LinearAlgebra]]
deps = ["Libdl"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "0fb723cd8c45858c22169b2e42269e53271a6df7"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.7"

[[Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[MbedTLS]]
deps = ["Dates", "MbedTLS_jll", "Random", "Sockets"]
git-tree-sha1 = "1c38e51c3d08ef2278062ebceade0e46cefc96fe"
uuid = "739be429-bea8-5141-9913-cc70e7f3736d"
version = "1.0.3"

[[MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"

[[Measures]]
git-tree-sha1 = "e498ddeee6f9fdb4551ce855a46f54dbd900245f"
uuid = "442fdcdd-2543-5da2-b0f3-8c86c306513e"
version = "0.3.1"

[[Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "4ea90bd5d3985ae1f9a908bd4500ae88921c5ce7"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.0.0"

[[Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"

[[NCDatasets]]
deps = ["CFTime", "DataStructures", "Dates", "NetCDF_jll", "Printf"]
git-tree-sha1 = "871f0b594d1e12cefd5520df03ba91c09f70b38d"
uuid = "85f8d34a-cbdd-5861-8df4-14fed0d494ab"
version = "0.11.6"

[[NaNMath]]
git-tree-sha1 = "bfe47e760d60b82b66b61d2d44128b62e3a369fb"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "0.3.5"

[[NetCDF_jll]]
deps = ["Artifacts", "HDF5_jll", "JLLWrappers", "LibCURL_jll", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Pkg", "Zlib_jll", "nghttp2_jll"]
git-tree-sha1 = "0cf4d1bf2ef45156aed85c9ac5f8c7e697d9288c"
uuid = "7243133f-43d8-5620-bbf4-c2c921802cf3"
version = "400.702.400+0"

[[NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"

[[Ogg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "887579a3eb005446d514ab7aeac5d1d027658b8f"
uuid = "e7412a2a-1a6e-54c0-be00-318e2571c051"
version = "1.3.5+1"

[[OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "15003dcb7d8db3c6c857fda14891a539a8f2705a"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "1.1.10+0"

[[Opus_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "51a08fb14ec28da2ec7a927c4337e4332c2a4720"
uuid = "91d4177d-7536-5919-b921-800302f37372"
version = "1.3.2+0"

[[OrderedCollections]]
git-tree-sha1 = "85f8e6578bf1f9ee0d11e7bb1b1456435479d47c"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.4.1"

[[PCRE_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b2a7af664e098055a7529ad1a900ded962bca488"
uuid = "2f80f16e-611a-54ab-bc61-aa92de5b98fc"
version = "8.44.0+0"

[[Parsers]]
deps = ["Dates"]
git-tree-sha1 = "bfd7d8c7fd87f04543810d9cbd3995972236ba1b"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "1.1.2"

[[Pixman_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b4f5d02549a10e20780a24fce72bea96b6329e29"
uuid = "30392449-352a-5448-841d-b1acce4e97dc"
version = "0.40.1+0"

[[Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"

[[PlotThemes]]
deps = ["PlotUtils", "Requires", "Statistics"]
git-tree-sha1 = "a3a964ce9dc7898193536002a6dd892b1b5a6f1d"
uuid = "ccf2f8ad-2431-5c83-bf29-c5338b663b6a"
version = "2.0.1"

[[PlotUtils]]
deps = ["ColorSchemes", "Colors", "Dates", "Printf", "Random", "Reexport", "Statistics"]
git-tree-sha1 = "501c20a63a34ac1d015d5304da0e645f42d91c9f"
uuid = "995b91a9-d308-5afd-9ec6-746e21dbc043"
version = "1.0.11"

[[Plots]]
deps = ["Base64", "Contour", "Dates", "FFMPEG", "FixedPointNumbers", "GR", "GeometryBasics", "JSON", "Latexify", "LinearAlgebra", "Measures", "NaNMath", "PlotThemes", "PlotUtils", "Printf", "REPL", "Random", "RecipesBase", "RecipesPipeline", "Reexport", "Requires", "Scratch", "Showoff", "SparseArrays", "Statistics", "StatsBase", "UUIDs"]
git-tree-sha1 = "e39bea10478c6aff5495ab522517fae5134b40e3"
uuid = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
version = "1.20.0"

[[PooledArrays]]
deps = ["DataAPI", "Future"]
git-tree-sha1 = "cde4ce9d6f33219465b55162811d8de8139c0414"
uuid = "2dfb63ee-cc39-5dd5-95bd-886bf059d720"
version = "1.2.1"

[[Preferences]]
deps = ["TOML"]
git-tree-sha1 = "00cfd92944ca9c760982747e9a1d0d5d86ab1e5a"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.2.2"

[[PrettyTables]]
deps = ["Crayons", "Formatting", "Markdown", "Reexport", "Tables"]
git-tree-sha1 = "0d1245a357cc61c8cd61934c07447aa569ff22e6"
uuid = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"
version = "1.1.0"

[[Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[Qt5Base_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Fontconfig_jll", "Glib_jll", "JLLWrappers", "Libdl", "Libglvnd_jll", "OpenSSL_jll", "Pkg", "Xorg_libXext_jll", "Xorg_libxcb_jll", "Xorg_xcb_util_image_jll", "Xorg_xcb_util_keysyms_jll", "Xorg_xcb_util_renderutil_jll", "Xorg_xcb_util_wm_jll", "Zlib_jll", "xkbcommon_jll"]
git-tree-sha1 = "ad368663a5e20dbb8d6dc2fddeefe4dae0781ae8"
uuid = "ea2cea3b-5b76-57ae-a6ef-0a8af62496e1"
version = "5.15.3+0"

[[REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[Random]]
deps = ["Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[RecipesBase]]
git-tree-sha1 = "b3fb709f3c97bfc6e948be68beeecb55a0b340ae"
uuid = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
version = "1.1.1"

[[RecipesPipeline]]
deps = ["Dates", "NaNMath", "PlotUtils", "RecipesBase"]
git-tree-sha1 = "2a7a2469ed5d94a98dea0e85c46fa653d76be0cd"
uuid = "01d81517-befc-4cb6-b9ec-a95719d0359c"
version = "0.3.4"

[[Reexport]]
git-tree-sha1 = "5f6c21241f0f655da3952fd60aa18477cf96c220"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.1.0"

[[Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "4036a3bd08ac7e968e27c203d45f5fff15020621"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.1.3"

[[SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"

[[Scratch]]
deps = ["Dates"]
git-tree-sha1 = "0b4b7f1393cff97c33891da2a0bf69c6ed241fda"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.1.0"

[[SentinelArrays]]
deps = ["Dates", "Random"]
git-tree-sha1 = "a3a337914a035b2d59c9cbe7f1a38aaba1265b02"
uuid = "91c51154-3ec4-41a3-a24f-3f23e20d615c"
version = "1.3.6"

[[Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[Showoff]]
deps = ["Dates", "Grisu"]
git-tree-sha1 = "91eddf657aca81df9ae6ceb20b959ae5653ad1de"
uuid = "992d4aef-0814-514b-bc4d-f2e9a6c4116f"
version = "1.0.3"

[[Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "b3363d7460f7d098ca0912c69b082f75625d7508"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.0.1"

[[SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[StaticArrays]]
deps = ["LinearAlgebra", "Random", "Statistics"]
git-tree-sha1 = "3240808c6d463ac46f1c1cd7638375cd22abbccb"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.2.12"

[[Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[StatsAPI]]
git-tree-sha1 = "1958272568dc176a1d881acb797beb909c785510"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.0.0"

[[StatsBase]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "fed1ec1e65749c4d96fc20dd13bea72b55457e62"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.33.9"

[[StructArrays]]
deps = ["Adapt", "DataAPI", "StaticArrays", "Tables"]
git-tree-sha1 = "000e168f5cc9aded17b6999a560b7c11dda69095"
uuid = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"
version = "0.6.0"

[[TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"

[[TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "TableTraits", "Test"]
git-tree-sha1 = "d0c690d37c73aeb5ca063056283fde5585a41710"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.5.0"

[[Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"

[[Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[URIs]]
git-tree-sha1 = "97bbe755a53fe859669cd907f2d96aee8d2c1355"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.3.0"

[[UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[Wayland_jll]]
deps = ["Artifacts", "Expat_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "3e61f0b86f90dacb0bc0e73a0c5a83f6a8636e23"
uuid = "a2964d1f-97da-50d4-b82a-358c7fce9d89"
version = "1.19.0+0"

[[Wayland_protocols_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Wayland_jll"]
git-tree-sha1 = "2839f1c1296940218e35df0bbb220f2a79686670"
uuid = "2381bf8a-dfd0-557d-9999-79630e7b1b91"
version = "1.18.0+4"

[[XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "1acf5bdf07aa0907e0a37d3718bb88d4b687b74a"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.9.12+0"

[[XSLT_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgcrypt_jll", "Libgpg_error_jll", "Libiconv_jll", "Pkg", "XML2_jll", "Zlib_jll"]
git-tree-sha1 = "91844873c4085240b95e795f692c4cec4d805f8a"
uuid = "aed1982a-8fda-507f-9586-7b0439959a61"
version = "1.1.34+0"

[[Xorg_libX11_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxcb_jll", "Xorg_xtrans_jll"]
git-tree-sha1 = "5be649d550f3f4b95308bf0183b82e2582876527"
uuid = "4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"
version = "1.6.9+4"

[[Xorg_libXau_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4e490d5c960c314f33885790ed410ff3a94ce67e"
uuid = "0c0b7dd1-d40b-584c-a123-a41640f87eec"
version = "1.0.9+4"

[[Xorg_libXcursor_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXfixes_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "12e0eb3bc634fa2080c1c37fccf56f7c22989afd"
uuid = "935fb764-8cf2-53bf-bb30-45bb1f8bf724"
version = "1.2.0+4"

[[Xorg_libXdmcp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fe47bd2247248125c428978740e18a681372dd4"
uuid = "a3789734-cfe1-5b06-b2d0-1dd0d9d62d05"
version = "1.1.3+4"

[[Xorg_libXext_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "b7c0aa8c376b31e4852b360222848637f481f8c3"
uuid = "1082639a-0dae-5f34-9b06-72781eeb8cb3"
version = "1.3.4+4"

[[Xorg_libXfixes_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "0e0dc7431e7a0587559f9294aeec269471c991a4"
uuid = "d091e8ba-531a-589c-9de9-94069b037ed8"
version = "5.0.3+4"

[[Xorg_libXi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll", "Xorg_libXfixes_jll"]
git-tree-sha1 = "89b52bc2160aadc84d707093930ef0bffa641246"
uuid = "a51aa0fd-4e3c-5386-b890-e753decda492"
version = "1.7.10+4"

[[Xorg_libXinerama_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll"]
git-tree-sha1 = "26be8b1c342929259317d8b9f7b53bf2bb73b123"
uuid = "d1454406-59df-5ea1-beac-c340f2130bc3"
version = "1.1.4+4"

[[Xorg_libXrandr_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "34cea83cb726fb58f325887bf0612c6b3fb17631"
uuid = "ec84b674-ba8e-5d96-8ba1-2a689ba10484"
version = "1.5.2+4"

[[Xorg_libXrender_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "19560f30fd49f4d4efbe7002a1037f8c43d43b96"
uuid = "ea2f1a96-1ddc-540d-b46f-429655e07cfa"
version = "0.9.10+4"

[[Xorg_libpthread_stubs_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "6783737e45d3c59a4a4c4091f5f88cdcf0908cbb"
uuid = "14d82f49-176c-5ed1-bb49-ad3f5cbd8c74"
version = "0.1.0+3"

[[Xorg_libxcb_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "XSLT_jll", "Xorg_libXau_jll", "Xorg_libXdmcp_jll", "Xorg_libpthread_stubs_jll"]
git-tree-sha1 = "daf17f441228e7a3833846cd048892861cff16d6"
uuid = "c7cfdc94-dc32-55de-ac96-5a1b8d977c5b"
version = "1.13.0+3"

[[Xorg_libxkbfile_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "926af861744212db0eb001d9e40b5d16292080b2"
uuid = "cc61e674-0454-545c-8b26-ed2c68acab7a"
version = "1.1.0+4"

[[Xorg_xcb_util_image_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "0fab0a40349ba1cba2c1da699243396ff8e94b97"
uuid = "12413925-8142-5f55-bb0e-6d7ca50bb09b"
version = "0.4.0+1"

[[Xorg_xcb_util_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxcb_jll"]
git-tree-sha1 = "e7fd7b2881fa2eaa72717420894d3938177862d1"
uuid = "2def613f-5ad1-5310-b15b-b15d46f528f5"
version = "0.4.0+1"

[[Xorg_xcb_util_keysyms_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "d1151e2c45a544f32441a567d1690e701ec89b00"
uuid = "975044d2-76e6-5fbe-bf08-97ce7c6574c7"
version = "0.4.0+1"

[[Xorg_xcb_util_renderutil_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "dfd7a8f38d4613b6a575253b3174dd991ca6183e"
uuid = "0d47668e-0667-5a69-a72c-f761630bfb7e"
version = "0.3.9+1"

[[Xorg_xcb_util_wm_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "e78d10aab01a4a154142c5006ed44fd9e8e31b67"
uuid = "c22f9ab0-d5fe-5066-847c-f4bb1cd4e361"
version = "0.4.1+1"

[[Xorg_xkbcomp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxkbfile_jll"]
git-tree-sha1 = "4bcbf660f6c2e714f87e960a171b119d06ee163b"
uuid = "35661453-b289-5fab-8a00-3d9160c6a3a4"
version = "1.4.2+4"

[[Xorg_xkeyboard_config_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xkbcomp_jll"]
git-tree-sha1 = "5c8424f8a67c3f2209646d4425f3d415fee5931d"
uuid = "33bec58e-1273-512f-9401-5d533626f822"
version = "2.27.0+4"

[[Xorg_xtrans_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "79c31e7844f6ecf779705fbc12146eb190b7d845"
uuid = "c5fb5394-a638-5e4d-96e5-b29de1b5cf10"
version = "1.4.0+3"

[[Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"

[[Zstd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "cc4bf3fdde8b7e3e9fa0351bdeedba1cf3b7f6e6"
uuid = "3161d3a3-bdf6-5164-811a-617609db77b4"
version = "1.5.0+0"

[[libass_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "acc685bcf777b2202a904cdcb49ad34c2fa1880c"
uuid = "0ac62f75-1d6f-5e53-bd7c-93b484bb37c0"
version = "0.14.0+4"

[[libfdk_aac_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "7a5780a0d9c6864184b3a2eeeb833a0c871f00ab"
uuid = "f638f0a6-7fb0-5443-88ba-1cc74229b280"
version = "0.1.6+4"

[[libpng_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "94d180a6d2b5e55e447e2d27a29ed04fe79eb30c"
uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f"
version = "1.6.38+0"

[[libvorbis_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Ogg_jll", "Pkg"]
git-tree-sha1 = "c45f4e40e7aafe9d086379e5578947ec8b95a8fb"
uuid = "f27f6e37-5d2b-51aa-960f-b287f2bc3b7a"
version = "1.3.7+0"

[[nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"

[[p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"

[[x264_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "d713c1ce4deac133e3334ee12f4adff07f81778f"
uuid = "1270edf5-f2f9-52d2-97e9-ab00b5d0237a"
version = "2020.7.14+2"

[[x265_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "487da2f8f2f0c8ee0e83f39d13037d6bbf0a45ab"
uuid = "dfaa095f-4041-5dcd-9319-2fabd8486b76"
version = "3.0.0+3"

[[xkbcommon_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Wayland_jll", "Wayland_protocols_jll", "Xorg_libxcb_jll", "Xorg_xkeyboard_config_jll"]
git-tree-sha1 = "ece2350174195bb31de1a63bea3a41ae1aa593b6"
uuid = "d8fb68d0-12a3-5cfd-a85a-d49703b185fd"
version = "0.9.1+5"
"""

# ╔═╡ Cell order:
# ╟─dd7d8178-f9a5-11eb-3166-3bf64f8a5b94
# ╠═68534a0f-d37f-4dc3-b16f-845de7a3616a
# ╠═413e150c-41de-4eaf-a9fe-297408e97039
# ╠═58066b35-ce6c-41e3-a055-de025099cbba
# ╠═777efcd0-c3e2-40c2-a225-4067fad3ffed
# ╠═57d1bf70-02c2-416c-bcf9-71fee1e5db16
# ╠═deb04563-40f4-4f3b-81dd-aca722946e06
# ╠═d720dc13-06e4-43e6-ac90-1f59ee628d1f
# ╟─4a933403-1159-4499-9da2-21806a7e9118
# ╟─0414004d-92c5-4c11-a66e-c787cf770f4f
# ╠═e4f5d63f-6f33-41b3-acb1-83e43cb48a41
# ╟─eb573962-b209-4947-ac4a-2157716c8230
# ╟─20a4022c-e6a6-4b27-8f79-64553aa85e14
# ╟─332007c6-361d-47f3-858a-6efec64a0956
# ╟─2a9f5c29-a0e3-4b12-be8f-b633b8ba134d
# ╟─7a3a7850-db85-4076-9ea7-3e6f808cd215
# ╟─d7887f87-9870-4d93-919d-a997fffece92
# ╟─2c865a00-f0e0-4f5d-83b1-53634a0e98be
# ╟─1863af7b-570a-4daf-9aaf-b937aa242678
# ╟─e88b7e6d-8312-4484-8310-56acb1afbe5b
# ╟─9119a97d-3066-41fd-b0ec-ba251273de9a
# ╟─936712ef-6c1d-481e-8fdc-45947c10c4c3
# ╟─44e159ca-926c-493c-a632-fae40f53bc13
# ╠═aaff210f-6978-4e6f-8282-a73eda938456
# ╠═3f72d620-687a-4196-a018-83a4829fdb55
# ╟─46921293-4fbb-4f90-aae0-16a1eae61264
# ╟─7077dfb9-d106-4289-9edc-d1f766628a36
# ╠═3e528c81-1d6d-42ef-925b-400e42683ca2
# ╠═88df45e1-4f2f-41f0-892a-09dfc4f3805d
# ╟─796443d5-2bcb-4333-99fc-6a3b86df8c0f
# ╠═bdcdad87-25e9-4590-ae8c-94acefd7c435
# ╟─81a8cc1e-c841-4de1-9b39-69af9393a8ca
# ╠═aae51c1f-e24d-4380-a87f-8f31bfbe41ca
# ╟─9dea6e5e-ea3e-4620-9ed2-9d5f0ee6b843
# ╠═2277a30e-63a9-49b9-bbc4-9c47510ed4c8
# ╟─27f1eccc-6580-4198-a45e-8d31e306cf6e
# ╠═d9595ed6-f743-4f4d-b66c-fcb447f800c2
# ╟─c844d780-e3e1-4680-9496-6bdd2382c951
# ╠═120378a8-1c97-47b6-b485-5b061d1ecb59
# ╟─93299161-ffad-4a2d-9892-19d94c41434a
# ╠═e3e77cc2-64ad-4105-b2aa-4607b2fc3025
# ╠═db4980a0-a510-4187-b110-6638b71aeb8a
# ╠═1f8aa5d9-7a16-4087-8ca8-377bf651e442
# ╠═69781e69-1a2b-464b-b032-5c50908cd89d
# ╠═528e9905-dfb0-43ac-b732-7d3e28416e4c
# ╠═32ced8ae-ce39-4c0d-a70d-54a97d92a8b5
# ╠═e655822f-7c68-4252-a557-4ecd12dcc892
# ╟─ea7eb11e-1070-4229-9f2d-809a7b1c5e7b
# ╟─1d2f62d7-88bf-4a34-88b7-94b9cee07b3f
# ╠═648a4b29-ac60-4cdc-9b32-7eec331fff9a
# ╠═3a005a47-4617-4e95-a45c-b2b71698e97a
# ╟─bed521e1-7afa-4553-a004-fb3f45b66c1e
# ╠═e1e24b52-2f09-47c7-abcc-0f0588b83e1a
# ╠═804909ab-e745-477a-9172-26ee4bbe09bb
# ╠═52ed2cab-64bb-476e-bc34-bb211ec6669a
# ╠═03b54197-d1ed-486d-bda4-5344b7cec738
# ╠═594f826a-6a42-43de-a3a5-66b82c6d9b44
# ╟─c0b0a7e2-9bb9-4562-9971-777dc2b28202
# ╠═8758332b-532d-45f5-bb1a-9b568e76b569
# ╠═9d37598f-4ae0-4e6b-a27d-542410eab3e0
# ╠═167b9732-ded5-4523-a8fd-e2daa5a4780c
# ╠═f329ef2b-2a6f-4a65-a191-84a10257b66e
# ╟─a6c40f6d-d747-4d54-b6f2-75bad19cd315
# ╠═705cd677-7a72-49e3-8964-a564dd872fdd
# ╠═ad79dad7-a9c0-4685-996e-67a51885c4f1
# ╠═e47cc9a8-8bed-49f9-917b-87f64f22cdd5
# ╠═8555e0d5-9fcb-4e69-b4be-d618554ed282
# ╟─6eefbf0e-6530-4792-8359-edd97db29fbb
# ╠═cbc110e3-a8ca-45e5-83fc-744f9156a67c
# ╠═2c7424a9-eb78-41bd-a985-7fb83f94499c
# ╠═063b4794-0c3f-4a1a-a484-ccc5d316d313
# ╠═8b831ccd-895a-416e-8c70-472c72896af8
# ╟─976be02c-22f0-4333-b815-eaa999af6046
# ╠═fb9d2b6d-3274-4292-986e-3393bdc06df4
# ╠═2fb0c711-2606-4913-8c1b-7e59d74b24d0
# ╠═6d5a5c24-d401-4109-bb91-1d62fb1eae81
# ╠═10a992bb-55dd-40e3-891e-95c53c12727e
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
