# Changelog

## v1.0 (working paper, 26 Oct 2026)

- **Another platform (E1):** Microsoft's Copilot-based AI applicability scores (Tomlinson et al. 2025, CC BY 4.0) run through the same crosswalk, weights, rankings and samples; rank indices for every specification and a two-platform composite.
- **Uncertainty (E3):** Dirichlet draws of crosswalk weights calibrated to the spread across schemes, EEH earnings draws from published relative standard errors, a survival table for every headline result, bands on the decile profile, and lower and upper bounds for unscored links.
- **Earnings or computer work (E4):** employment-weighted rank regressions with teleworkability (Dingel and Neiman 2020; GPL-3.0, aggregate use only) and each potential measure, a Gelbach decomposition and an ORIV estimate.
- Abstract, key findings, introduction, theory reading, limitations and conclusion updated for the new results; three appendix sections; two figures.
- `R/fn_units.R` holds the unit table and specification grid shared by the analysis scripts; 106 tests.

## v0.9 (working draft, comments welcome)

- **Note**, rendered to HTML and PDF:
  - an abstract and five key findings; usage-based AI exposure across Australian earnings deciles in one main specification;
  - concentration among higher earners, compared across measures on ranks (rank and Erreygers indices) as well as the level index;
  - the usage-potential gap against JSA automation, JSA augmentation, Eloundou et al. and AIOE, with the range across weighting schemes;
  - the extensive margin and intensity, with a log decomposition and a capability analogue; women and men, split within and between deciles; Western Australia, with contributions measured relative to the national mean; usage relative to employment by SOC major group;
  - robustness built around the concentration index, a lower bound for unscored links, gaps without zero-exposure units, and the influence of single large units with deciles re-formed;
  - a condensed reading of the results through a two-capital model of the skill premium, with symbolically verified responses;
  - author-year citations, figure titles that state findings, and a provenance and disclosure section.
- **Appendix:** every alternative specification (60 in total) with slopes and rank indices, a smoothed profile, margins by decile, influence checks, size-weighted disagreements, a review of the 40 largest units, crosswalk validation, earnings imputations, sources and licences.
- **Occupation explorer** for all 358 ANZSCO v1.2 unit groups.
- **Other documents:** the summary, methods memo, explainer and decision log.
- **Reproducibility:** `make all` reproduces every output from public sources. 98 tests, a clean-clone check, and prose and licence checks pass.
