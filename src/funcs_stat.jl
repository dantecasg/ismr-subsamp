# --------------------------------------------------------------------------- #
# Set of statistical functions used in the study.
# Author: Dante T. Castro Garro
# Date: 2021-10-30
# Version: 0.3.0
# --------------------------------------------------------------------------- #

## sptCor
# Spatial corralation for a 2D variable
# ........................................................................... #
# Required libraries;
# - Statistics
# - HypothesisTests
# - Distributions
# ........................................................................... #
# Parameters:
# - x -> 3 dimensional variable
# - y -> 1 or 3 dimensional variable
# - pval -> calculate the pvalues
# - sig -> significance level
# - autocor -> consider autcorrelation
# ........................................................................... #
# Notes:
# - pvalue calculation based on `hypothesisTests.CorrelationTest` and 
# https://www.statology.org/p-value-correlation-excel/

function sptCor(x, y; pval = false, sig = 0.05, autocor = false)
    
    nx = size(x, 1)
    ny = size(x, 2)
    nd = size(y) |> length
    spt_cor = Array{Union{Missing, Float64}}(missing, nx, ny)
    spt_pvl = Array{Union{Missing, Float64}}(missing, nx, ny)

    if nd == 1
        y_new = convert(Vector{Float64}, y)
        pen_y = autocor ? autoCorLevel(y_new, sig) : 0 # Convert from a vector type Float + Missing to just Float is necessary
    end
    
    for i in 1:nx, j in 1:ny
        
        if nd > 1; y_new = convert(Vector{Float64}, y[i,j,:]); end # Convert from a vector type Float + Missing to just Float is necessary
        
        if any(x -> !ismissing(x), x[i,j,:]) && any(x -> !ismissing(x), y_new)
            
            pen_x = autocor ? autoCorLevel(x[i,j,:], sig) : 0
            pen_y = autocor ? autoCorLevel(y_new, sig) : 0
            
            spt_cor[i,j] = cor(x[i,j,:], y_new)
            # pvl = pvalue(CorrelationTest(x[i,j,:], y_new))
            pvl = corPval(x[i,j,:], y_new, pen = pen_x + pen_y)
            spt_pvl[i,j] = pvl <= sig ? 1 : missing
            
        end
        
    end
    
    if pval
        return spt_cor, spt_pvl
    else
        return spt_cor
    end
    
end

## autoCorLevel
# Determines the lag where autocorrelation is significant
# ........................................................................... #
# Requieres:
# - Distributions
# * corPval
# ........................................................................... #
# Parameters:
# - x -> time series
# - sig > significance level

function autoCorLevel(x, sig)
    
    pen = 0
    pval = 0.0
    
    while pval <= sig
        pen = pen + 1
        pval = corPval(x[1:end-pen], x[1+pen:end])
    end
    
    return pen - 1
    
end

## corPval
# Calculates the p-value of correlation using T-test and considering a 
# reduction in degrees
# ........................................................................... #
# Requieres:
# - Distributions
# ........................................................................... #
# Parameters:
# - x, y -> time series
# - pen > penality for the degrees of freedom

function corPval(x, y; pen = 0)
    
    r = cor(x, y)
    n = length(x)
    dof = n - 2 - pen
    t = r * sqrt(dof / (1 - r^2))
    td = TDist(dof)
    pval = min(2 * min(cdf(td, t), ccdf(td, t)), 1.0)
    return pval
    
end

## normalize
# Normalize a time series
# ........................................................................... #
# Required libraries;
# - Statistics
# ........................................................................... #
# Parameters:
# - x -> time series

function normalize(x)
    return (x .- mean(x)) ./ std(x)
end

## corNaN
# Normal pearson correlation considering NaN values
# ........................................................................... #
# Required libraries;
# - Statistics
# ........................................................................... #
# Parameters:
# - x -> time series

function corNaN(x, y)
    xn = []
    yn = []
    for i in 1:length(x)
        if !isnan(x[i]) && !isnan(y[i])
            push!(xn, x[i])
            push!(yn, y[i])
        end
    end
    res = cor(xn, yn)
    return res
end

## runMean
# Running mean for a time series
# ........................................................................... #
# Required libraries;
# - Statistics
# ........................................................................... #
# Parameters:
# - x -> time series
# - w -> window size (must be an odd number)

function runMean(x, w)
    n = size(x, 1)
    ext = Int( (w - 1) / 2 )
    ini = 1 + ext
    fin = n - ext
    res = zeros(n)

    for i in ini:fin
        res[i] = mean(x[(i-ext):(i+ext)])
    end

    return res[ini:fin]
end
