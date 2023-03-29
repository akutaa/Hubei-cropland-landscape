library(conflicted)
library(magrittr)
library(tidyverse)
library(tidyr)
library(terra)
library(sf)
library(landscapemetrics)

# shape metric: contig, frac, shape, 
# core area metric: cai, dcad, 
# area and edge metric: ed, lpi, 
# aggregation metric: ai, lsi, pd

setwd("E:/Code/data/")

selsm <- function(yr, scl)
{
  print(paste('start',yr,scl,'km','...',sep = ' '))
  inRas <- rast(paste0('CLCD',yr,'_200m.tif'))
  fishnet <- st_read(paste0('net',scl,'km.shp'))
  mtrc <- sample_lsm(landscape = inRas,
                     y = fishnet,
                     level = 'class',
                     metric = c(
                       'contig', 'frac', 'shape', 
                       'cai', 'dcad', 
                       'ed', 'lpi', 
                       'ai', 'lsi', 'pd'
                     ),
                     plot_id = fishnet$PID,
                     directions = 8,
                     neighbourhood = 8,
                     progress = TRUE
                     )
  print(paste0(yr,' ',scl,'km calc done!'))
  save(mtrc,file = paste0(yr,'_',scl,'km.RData'))
  mtrc2 <- mtrc
  mtrc2 <- dplyr::filter(mtrc, class == 1) %>% 
    pivot_wider(names_from = metric,values_from = value)
  outfishnet <- merge(x = fishnet,y = mtrc2,by.x="PID",by.y="plot_id",all.x=TRUE) %>% 
    st_write(paste0('out_',yr,'_',scl,'km.shp'))
  print(paste0(yr,' ',scl,'km complete!'))
}

scllist <- c(3:10)
yrlist <- list(2000,2005,2010,2015,2020)

for (yr in yrlist){
  for (scl in scllist){
    selsm(yr,scl)
  }
}


# batch generate points for gd
GD_point <- function(r){
  load(paste0('2020_',r,'_mtc.RData'))
  m <- dplyr::filter(metric, class == 1) %>%
    pivot_wider(names_from = metric,values_from = value) %>% 
    select(-c(layer,level,class,id))
  p <- st_read(paste0('HubeiSP',r,'.shp')) %>%
    merge(y = m,by.x="GRID_ID",by.y="plot_id",all.x=TRUE) %>%
    st_write(paste0('P_',r,'.shp'))
}
