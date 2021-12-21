# --------------------------------------------------------------------------- #
# Script to test the ensemble data for AMM
# --------------------------------------------------------------------------- #

# =========================================================================== #
# LIBRERÍAS
# =========================================================================== #

library(dplyr)
library(ggplot2)
library(cowplot)
library(lubridate)

# =========================================================================== #
# FUNCIONES
# =========================================================================== #

# Normalize
normal = function(x) {
    res = (x - mean(x)) / sd(x)
    return(res)
}

# =========================================================================== #
# PROCEDIMIENTO
# =========================================================================== #

options(stringsAsFactors = FALSE)

# Loading data
obs = read.csv("../../../data/index/amm-obs_1981-2016-mon.csv") %>%
    as_tibble() %>%
    mutate(
        time = as.Date(time, "%Y-%m-%d"),
        year = year(time),
        month = month(time)) %>%
    filter(month %in% 6:8) %>%
    group_by(year) %>%
    summarize(amm = mean(amm)) %>%
    ungroup() %>%
    mutate(amm = normal(amm))

asm = read.csv("../../../data/index/amm-asm_1981-2016-mon.csv") %>%
    as_tibble() %>%
    mutate(
        time = as.POSIXct(time) %>% as.Date(),
        year = year(time),
        month = month(time)) %>%
    filter(month %in% 6:8) %>%
    group_by(year) %>%
    summarize(amm = mean(amm)) %>%
    ungroup() %>%
    mutate(amm = normal(amm))

ens = read.csv("../../../data/index/amm-ens_1981-2016-mon.csv") %>%
    as_tibble() %>%
    mutate(
        time = as.POSIXct(time) %>% as.Date(),
        year = year(time),
        month = month(time)) %>%
    filter(month %in% 6:8) %>%
    group_by(year, ens) %>%
    summarize(amm = mean(amm)) %>%
    group_by(ens) %>%
    mutate(amm = normal(amm)) %>%
    ungroup()

ref = read.table("../../../data/index/AMM.txt", header = TRUE) %>%
    as_tibble() %>%
    select(year = Year, month = Mo, amm = SST) %>%
    mutate( time = as.Date(paste0(year, "-", month, "-01")) ) %>%
    filter(month %in% 6:8, year %in% 1981:2016) %>%
    group_by(year) %>%
    summarize(amm = mean(amm)) %>%
    ungroup() %>%
    mutate(amm = normal(amm))

# Plotting
col = c("obs" = "brown", "asm" = "royalblue", "ref" = "black")

g_ref = ggplot(mapping = aes(x = year, y = amm)) +
    geom_point(data = ens, colour = "black", alpha = 0.2) +
    geom_line(data = obs, mapping = aes(colour = "obs")) +
    geom_line(data = asm, mapping = aes(colour = "asm")) +
    geom_line(data = ref, mapping = aes(colour = "ref")) +
    scale_colour_manual(values = col) +
    theme_minimal() +
    panel_border()
