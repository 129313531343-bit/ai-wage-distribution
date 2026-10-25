# make all   : fetch inputs, build every table, run the tests
# make check : tests plus the publication checks in R/check.R
# The three BLS files must be downloaded by hand into data/raw/manual/ first (see README).

R := Rscript

.PHONY: all fetch build test check clean

all: fetch build test

fetch:
	$(R) R/01_fetch.R

build:
	$(R) R/02_profile_aei.R
	$(R) R/03_classifications.R
	$(R) R/04_employment.R
	$(R) R/05_earnings.R
	$(R) R/06_measures.R
	$(R) R/07_links_lmi.R
	$(R) R/08_crosswalks.R
	$(R) R/09_unit_measures.R
	$(R) R/10_review.R
	$(R) R/11_analysis.R
	$(R) R/12_charts.R

test:
	$(R) -e 'testthat::test_dir("tests/testthat", stop_on_failure = TRUE)'

check: test
	$(R) R/check.R

clean:
	rm -rf data/interim/*.csv data/out/*
