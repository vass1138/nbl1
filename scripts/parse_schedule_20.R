# clear all objects from current session
# rm(list = ls(all = TRUE))

# set working directory (.here)
library(here)
getwd()

library(dplyr)

# library(pdftools)
# pdf <- pdf_text("nbl1-south-fixture-2021.pdf")

# install.packages("tabulizer")
library(tabulizer)

out <- extract_tables("../misc/nbl1-south-fixture-2021.pdf",output=c("csv"),outdir=".")
