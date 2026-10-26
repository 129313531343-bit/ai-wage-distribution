# make all   : fetch inputs, build every table, run the tests
# make check : tests plus the publication checks in R/check.R
# make note  : render the note, appendix and methods memo to note/_rendered and docs/_rendered
# The three BLS files must be downloaded by hand into data/raw/manual/ first (see README).

R := Rscript

.PHONY: all fetch build test check note explorer-check theory-check clean

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
	$(R) R/16_top40_checks.R
	$(R) R/17_other_platform.R
	$(R) R/18_uncertainty.R
	$(R) R/19_conditional.R
	$(R) R/12_charts.R
	$(R) R/15_replicate_g.R
	$(R) R/13_facts.R
	$(R) R/14_explorer.R

test:
	$(R) -e 'testthat::test_dir("tests/testthat", stop_on_failure = TRUE)'

check: test
	$(R) R/check.R

# Render the note, appendix and methods memo (see R/render.sh for why it uses a temporary copy).
note:
	sh R/render.sh

# Explorer acceptance check at 375 px (needs Playwright for Python: pip install playwright && playwright install chromium).
explorer-check:
	python3 tests/explorer_check.py

# Symbolic and numerical checks of the theory box (needs sympy).
theory-check:
	python3 theory/check_theory.py | tee theory/check_theory_output.txt

clean:
	rm -rf data/interim/*.csv data/out/*
