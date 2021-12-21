### A Pluto.jl notebook ###
# v0.14.7

using Markdown
using InteractiveUtils

# ╔═╡ 3ec22682-c823-11eb-2271-d11be084712d
using NCDatasets

# ╔═╡ ee8a20d7-bd8d-4cb8-b465-2ba9b96de441
using Plots

# ╔═╡ 78a795c6-ce52-498b-b9d4-fa2239d86803
using Statistics

# ╔═╡ 437c29cf-505f-4060-a49d-dc5b935e5e3b
using DataFrames

# ╔═╡ 2d4dbd6f-8168-4d26-b13e-a76bdf423feb
using CSV

# ╔═╡ 9a81795f-b6e4-471a-b26a-4f7571d8a444
md"# Libraries"

# ╔═╡ 267c5d6f-06fc-4b27-b47f-e059eddd800c
md"""
# Data
"""

# ╔═╡ 993de7d9-d178-4645-8fec-153613caa06a
datapath = "../../../data/";

# ╔═╡ 7314d73a-2440-4d12-8a00-27d062ddfcb7
assim = Dataset(datapath * "MR30/as_1981-2017_precip_JJAS.nc");

# ╔═╡ 125ca756-8cd4-4c53-8b58-1782f98b1cb2
runs = Dataset(datapath * "MR30/mr30-run_1981-2017_precip_JJAS.nc");

# ╔═╡ 6152fa11-52d3-45b8-888f-950809ee0934
gpcp = Dataset(datapath * "GPCP/GPCP_1981-2017_JJAS.nc");

# ╔═╡ 4dee5e30-219d-4e80-896b-24e589ca5a40
imd = Dataset(datapath * "IMD/IMD_1981-2017_JJAS.nc");

# ╔═╡ 3f0087d7-332b-44d3-8f33-1bec44f9ed42
md"""
# Processing

## Precipitation
"""

# ╔═╡ 263502d2-4322-48a3-b6f2-14ef648ee21b
# Reading variables
begin
	tm = runs["time"]
	pp_assim = assim["precip"][1,1,:]
	pp_runs = runs["precip"][1,1,:,:]
	pp_runs_t = pp_runs'
	pp_gpcp = gpcp["precip"]
	pp_imd = imd["precip"][1,1,1:35]
end;

# ╔═╡ d9c0c6dc-b7a0-4861-82da-5e955cf707ea
# Anomalies
begin
	anom_assim = pp_assim .- mean(pp_assim)
	anom_runs  = pp_runs .- mean(pp_runs)
	anom_gpcp  = pp_gpcp .- mean(pp_gpcp)
	anom_imd   = pp_imd .- mean(pp_imd)
end;

# ╔═╡ 12e3d47a-845a-4145-aaeb-ae505c117107
# Mean of ensembles
begin
	pp_ens = mean(pp_runs, dims = 1)'
	anom_ens = mean(anom_runs, dims = 1)'
end;

# ╔═╡ 348869c9-c514-4d6e-b619-6f33e7343a33
# De-grouping members
begin
	pp_runs_d = vec(pp_runs')
	anom_runs_d = vec(anom_runs')
	tm_d = repeat(tm, 30)
end;

# ╔═╡ 334203ae-f144-40e8-a2d6-5d094f9f240c
anom_runs

# ╔═╡ 3162b9fb-835c-4ffb-a8d7-f6376ceb871a
cor(anom_assim, anom_ens)

# ╔═╡ fcbb7637-59f2-47be-b859-af9ba4a36b3d
cor(anom_gpcp, anom_ens)

# ╔═╡ be7bda4e-246f-4b91-b16a-306b89231d33
cor(anom_imd, anom_ens[1:35])

# ╔═╡ 1cc9ba2b-2dd6-471c-b6ee-c23243d8eeec
begin
	scatter(tm, pp_runs', legend = false, markercolor = "royalblue", alpha = 0.2)
	plot!(tm, pp_ens, lw = 2, linecolor = "brown")
	plot!(tm, pp_assim, lw = 3, linecolor = "black")
	plot!(tm, pp_gpcp, lw = 2, linecolor = "forestgreen")
	plot!(tm[1:35], pp_imd, lw = 2, linecolor = "orange")
	title!("Ensemble vs Assimilation")
	ylabel!("mm/day")
end

# ╔═╡ 33be8fee-d61c-44a2-aad6-d464ab2c6998
begin
	pp = scatter(tm_d, anom_runs_d, label = "Members", markercolor = "royalblue", alpha = 0.2)
	plot!(tm, anom_ens, lw = 2, linecolor = "brown", label = "Mean ensamble")
	plot!(tm, anom_assim, lw = 2, linecolor = "black", label = "Assimilation")
	plot!(tm, anom_gpcp, lw = 2, linecolor = "forestgreen", label = "GPCP")
	plot!(tm[1:35], anom_imd, lw = 2, linecolor = "orange", label = "IMD")
	hline!([0], linecolor = "gray", label = "")
	plot!(legend = :outerbottom)
	title!("Comparison of precipitation anomalies")
	ylims!((-2,2))
	ylabel!("mm/day")
end

# ╔═╡ 92b7bf2f-e9a1-44ec-8750-9af904176ad5
savefig(pp, "../img/precip.png")

# ╔═╡ 34b016f9-7d65-46a9-9dc1-1cd3892d25df
md"""
## Spatial correlation
"""

# ╔═╡ 887ca4de-1577-4014-a729-1735e5954dcb
md"""
## ENSO
"""

# ╔═╡ dd2f4a76-1ec8-4f25-8dec-f0f805d0dfe6
# ONI Index
begin
	oni = DataFrame(CSV.File(datapath * "ENSO/cpc_oni_ori.csv"))
	oni_81_17 = oni[(oni.Year .>= 1981) .& (oni.Year .<= 2017),:]
	
	oni_mr30 = CSV.File(datapath * "ENSO/mr30_oni.csv"; missingstrings = ["NA"])
	oni_mr30 = DataFrame(oni_mr30)
	oni_mr30 = oni_mr30[(oni_mr30.year .>= 1981),:]
end;

# ╔═╡ a231b6f1-4288-48f1-adde-8e761f233bb5
md"""
### Correlation with precipitation
"""

# ╔═╡ 1edb965d-b958-4990-a57e-d3ca6f415466
begin
	oni_gpcp_corr = Array{Float64}(undef, 5)
	per = ["JFM","FMA","MAM","AMJ"]
	for i in 1:length(per)
		oni_gpcp_corr[i] = cor(anom_gpcp, oni_81_17[:,per[i]])
	end
end

# ╔═╡ b5d469b1-2c9d-48d0-8e5a-a4f2123d5ed3
begin
	oni_gpcp = scatter(oni_81_17[:,:DJF], anom_gpcp, label = "DJF")
	scatter!(oni_81_17[:,:JFM], anom_gpcp, label = "JFM")
	scatter!(oni_81_17[:,:FMA], anom_gpcp, label = "FMA")
	scatter!(oni_81_17[:,:MAM], anom_gpcp, label = "MAM")
	scatter!(oni_81_17[:,:AMJ], anom_gpcp, label = "AMJ")
	title!("Scatter plot ONI (diff. months) vs GPCP")
	xlabel!("ONI")
	ylabel!("Precip. anomaly (mm/day)")
end

# ╔═╡ 52250d84-83e8-44d9-a13a-0896b1cf7e17
savefig(oni_gpcp, "../img/oni_gpcp.png")

# ╔═╡ fb23904f-ce94-481b-98ba-74330f39159e
begin
	oni_cpc_mr30 = scatter(oni_mr30[:,:DJF], oni_81_17[:,:DJF], label = "DJF")
	scatter!(oni_mr30[:,:JFM], oni_81_17[:,:JFM], label = "JFM")
	scatter!(oni_mr30[:,:FMA], oni_81_17[:,:FMA], label = "FMA")
	scatter!(oni_mr30[:,:MAM], oni_81_17[:,:MAM], label = "MAM")
	scatter!(oni_mr30[:,:AMJ], oni_81_17[:,:AMJ], label = "AMJ")
	plot!(legend = :bottomright)
	title!("Scatter plot ONI MR30 vs CPC")
	xlabel!("MR30")
	ylabel!("CPC")
end

# ╔═╡ c3dac4d3-81d4-4616-b296-9060c18a442c
savefig(oni_cpc_mr30, "../img/oni_cpc_mr30.png")

# ╔═╡ 09895e26-ba9e-4040-b8a2-abc55683387a
# Members correlation with ONI index
begin
	oni_mem_cor = zeros((30,5))
	for i in 1:30
		for j in 1:5
			oni_mem_cor[i,j] = cor(oni_81_17[:,j+1], pp_runs_t[:,i])
		end
	end
end

# ╔═╡ e01bf8d0-8548-4db9-80bc-c8acfbb34dde
begin
	oni_mem_cor_fig = scatter(1:30, oni_mem_cor[:,1], label = "DJF")
	scatter!(1:30, oni_mem_cor[:,2], label = "JFM")
	scatter!(1:30, oni_mem_cor[:,3], label = "FMA")
	scatter!(1:30, oni_mem_cor[:,4], label = "MAM")
	scatter!(1:30, oni_mem_cor[:,5], label = "AMJ")
	hline!([0], linecolor = "gray", label = "")
	plot!(legend = :top)
	ylims!((-1,1))
	title!("Correlation between Members and ONI Index (CPC)")
	xlabel!("Members")
	ylabel!("Pearson corr.")
end

# ╔═╡ ef924627-cb6b-41c8-b667-d2d3fdcc8b58
savefig(oni_mem_cor_fig, "../img/oni_mem_cor.png")

# ╔═╡ Cell order:
# ╟─9a81795f-b6e4-471a-b26a-4f7571d8a444
# ╠═3ec22682-c823-11eb-2271-d11be084712d
# ╠═ee8a20d7-bd8d-4cb8-b465-2ba9b96de441
# ╠═78a795c6-ce52-498b-b9d4-fa2239d86803
# ╠═437c29cf-505f-4060-a49d-dc5b935e5e3b
# ╠═2d4dbd6f-8168-4d26-b13e-a76bdf423feb
# ╟─267c5d6f-06fc-4b27-b47f-e059eddd800c
# ╠═993de7d9-d178-4645-8fec-153613caa06a
# ╠═7314d73a-2440-4d12-8a00-27d062ddfcb7
# ╠═125ca756-8cd4-4c53-8b58-1782f98b1cb2
# ╠═6152fa11-52d3-45b8-888f-950809ee0934
# ╠═4dee5e30-219d-4e80-896b-24e589ca5a40
# ╟─3f0087d7-332b-44d3-8f33-1bec44f9ed42
# ╠═263502d2-4322-48a3-b6f2-14ef648ee21b
# ╠═d9c0c6dc-b7a0-4861-82da-5e955cf707ea
# ╠═12e3d47a-845a-4145-aaeb-ae505c117107
# ╠═348869c9-c514-4d6e-b619-6f33e7343a33
# ╠═334203ae-f144-40e8-a2d6-5d094f9f240c
# ╠═3162b9fb-835c-4ffb-a8d7-f6376ceb871a
# ╠═fcbb7637-59f2-47be-b859-af9ba4a36b3d
# ╠═be7bda4e-246f-4b91-b16a-306b89231d33
# ╟─1cc9ba2b-2dd6-471c-b6ee-c23243d8eeec
# ╠═33be8fee-d61c-44a2-aad6-d464ab2c6998
# ╠═92b7bf2f-e9a1-44ec-8750-9af904176ad5
# ╟─34b016f9-7d65-46a9-9dc1-1cd3892d25df
# ╟─887ca4de-1577-4014-a729-1735e5954dcb
# ╠═dd2f4a76-1ec8-4f25-8dec-f0f805d0dfe6
# ╟─a231b6f1-4288-48f1-adde-8e761f233bb5
# ╠═1edb965d-b958-4990-a57e-d3ca6f415466
# ╠═b5d469b1-2c9d-48d0-8e5a-a4f2123d5ed3
# ╠═52250d84-83e8-44d9-a13a-0896b1cf7e17
# ╠═fb23904f-ce94-481b-98ba-74330f39159e
# ╠═c3dac4d3-81d4-4616-b296-9060c18a442c
# ╠═09895e26-ba9e-4040-b8a2-abc55683387a
# ╠═e01bf8d0-8548-4db9-80bc-c8acfbb34dde
# ╠═ef924627-cb6b-41c8-b667-d2d3fdcc8b58
