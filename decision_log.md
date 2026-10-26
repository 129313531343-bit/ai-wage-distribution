# Decision log

This file records three things: Luc Taya's decisions (with dates), the method choices fixed before any results were produced (and any later change to them), and method notes that a reader needs in order to check the pipeline. Claude Code keeps the log. A decision entry quotes Luc's words where possible and does not add reasons Luc did not give.

## Decisions

### D1. Kill/pivot call (M0)

- **Date:** 25 October 2026
- **Decided by:** Luc Taya, in chat
- **Decision:** "continue with the narrowed novelty claim (gap by earnings decile, margins, WA composition, sex; cite DEWR 2026 as the mapping base)".
- **Evidence:** `docs/novelty_search.md`, especially H1 (DEWR 2026) and section 6.
- **Rule applied:** neither (a) nor (b) applies as written. The outcome matches (a): the headline stays the usage-potential gap, the WA composition and sex results are kept, and DEWR (2026) is cited as the base for the AEI-to-ANZSCO mapping. The project does not claim a first mapping.
- **Open risk:** the call was made before the manual checks in section 5 of `docs/novelty_search.md`. Demirev (2026) and Levkoff (2026) could only be seen as snippets. If either reports the usage-potential gap by Australian earnings decile, rule (b) reopens and comes back to Luc.

### D2. Rule (c): the NSC/LMI ANZSCO to O*NET-SOC correspondence

- **Date:** 25 October 2026
- **Decided by:** Luc Taya, in chat
- **Decision:** "fourth scheme plus validation (demote to validation only if the licence can't be verified)".
- **What this means for the build:**
  - The archived *ANZSCO 2013 to O*NET-SOC 2019* file (ANZSCO v1.3) becomes weighting scheme 4. It is also a check on the primary SOC 2018 → SOC 2010 → ISCO-08 → ANZSCO v1.2 chain.
  - The file's Notes sheet says it is coded to ANZSCO 2013 v1.2, so no bridge is needed (checked in M1). It mixes 4-digit and 6-digit ANZSCO codes and grades each link's strength of match.
  - The Internet Archive URL, capture date and sha256 go in `data/raw/MANIFEST.csv`.
  - How SOCs are weighted within scheme 4 is logged in M2 and reviewed at walk-through 1.
  - If the licence cannot be verified in M1, scheme 4 is dropped to validation only, and that change is logged here.
  - **M1 outcome:** the licence was verified as CC BY 4.0 from the archived LMI copyright page (captured 3 Jan 2024), and the file states its own required attribution. Scheme 4 stays.

### D3. AEI licence

- **Date:** 25 October 2026
- **Decided by:** Luc Taya, in chat
- **Decision:** "record as stated and draft the email for me to send".
- **Recording:** the MANIFEST gives the licence as "CC-BY (version not stated on dataset card); HF metadata tag: MIT". The card text is quoted in the notes column, and the commit is pinned.
- **Email:** Claude Code drafts it in `private/` (not published). Luc sends it. Any reply is logged here.

### D5. Scope of the prose checks in `make check`

- **Date:** 25 October 2026
- **Decided by:** Luc Taya, in chat
- **Decision:** "checks on note, summary and memo only".
- **What this means:** the bare-digit and causal-word checks run on the note, the 800-word summary and the methods memo. They do not run on logs such as this file or `docs/novelty_search.md`. The check for per-unit AIOE columns still runs on every published file.

### D6. Conflict-of-interest line in the README

- **Date:** 25 October 2026
- **Decided by:** Luc Taya, in chat
- **Decision:** "use your proposed wording". This text is added to "Contributions and AI use": "The data analysed are published by Anthropic, and the pipeline was written with Claude Code, an Anthropic product. Anthropic had no role in this project and has not reviewed or endorsed it."

### D8. Order of work and description

- **Date:** 25 October 2026
- **Decided by:** Luc Taya, in chat
- **Decision:** "Build the full analysis first; after M2 results, draft the research question and framing for me to edit. Describe the work as descriptive analysis." Luc also asked Claude Code to do as much as it can and to batch anything that needs Luc.
- **What this means:**
  - The separate questions file (`docs/questions.md`) and its 27 Oct deadline are dropped.
  - The method choices Luc would have set there are now defaults set by Claude Code before any results (C1-C8 below).
  - The research question and framing are drafted by Claude Code after the first results, for Luc to edit. The README says so.

### D11. Delegation of remaining decisions and writing (26 Oct 2026)

- **Date:** 26 October 2026
- **Decided by:** Luc Taya, in chat
- **Decision:**
  - D4, D7 and D9: "use your judgement. Pick whatever gives the clearest, most defensible main result and the least confusing presentation. Lead with one clean main specification", with every alternative in a labelled appendix table, nothing dropped, and each choice logged with its reason.
  - D10: done by Claude using automated checks.
  - Framing, takeaways and theory box: written by Claude.
  - Walk-throughs 1-3: skipped, replaced by `docs/explainer.md`.
  - Reviewers: the memo goes after release.
  - Optional extras F and H: skipped.
- **Consequence for the README:** "Contributions and AI use" now says Claude wrote the analysis code, framing, takeaways and theory section, and Luc reviewed and approved them. That statement must be true before the repository is made public.

### D4. Earnings ranking in the main text (decided by Claude under D11, 26 Oct 2026)

- **Choice:** the main text uses only the primary ranking, EEH weekly earnings (C1). EEH hourly (cube 13) and ATO average salary or wages appear in the appendix sensitivity table and an appendix chart.
- **Reason:** C1 was fixed before any result was seen. Replacing it with whichever alternative looks cleanest after seeing results would invite a specification-search objection. Showing every alternative in one labelled table answers it.

### Main specification (decided by Claude under D11, 26 Oct 2026)

- **Choice:** weighting scheme 1 (OEWS employment weights), all units, EEH weekly ranking. The three potential measures (JSA automation, which is the primary comparator under C5; JSA augmentation; Eloundou beta) stay side by side in the main gap chart, because they are comparators, not alternative specifications.
- **Moved to the appendix:** the range across schemes (an appendix chart), schemes 2-4, non-diffuse units, the RSE and owner-operator exclusions, and the Sales Assistants influence check.
- **Reason:** every part of the main specification was fixed before results (C3-C5). The robustness results are reported in full, including where the rule in C6 fails.

### D7. Licences (decided by Claude under D11, 26 Oct 2026)

- **Choice:**
  - Code: MIT (`LICENSE`).
  - Text, figures and derived tables written for this project: CC BY 4.0 (`LICENSE-CONTENT.md`).
  - Third-party data keep their own licences (`docs/credits.md`). AIOE values are not redistributed.
- **Reason:** permissive licences let readers reuse and check the work. CC BY matches the licence of most inputs (ABS, JSA, O*NET, AEI as stated).

### D9. Owner-operator list (decided by Claude under D11, 26 Oct 2026)

- **Choice:** keep the draft list in `R/fn_owner_managers.R` (13 units) for the exclusion run.
- **Reason:** ABS publishes form of employment only by occupation major group, so no data-based unit-level list exists. A short, transparent judgement list, with the exclusion's results shown in the appendix, is more defensible than an unexplained or longer one. The limitation is stated in the note.

### Pending decisions

| ID | Question | Status |
|---|---|---|
| D10 | Top-40 review: done by Claude with automated checks under D11 (see N20) | Done |

## Method choices fixed before results

Claude Code set these defaults on 25 October 2026 under D8, before any result was produced. Luc can change them at review. A change made after results exist is logged here with its date and reason.

- **C1. Primary earnings ranking.** If an EEH May 2025 cube gives hourly earnings at 4-digit with usable RSEs, use it, because weekly earnings mix pay rates with hours worked. Otherwise use cube 11: average weekly total cash earnings, all employees, 4-digit. M1 checks which case applies and records the result in the method notes. EEH excludes owner-managers while EQ08 counts all employed people; this is stated in the note.
- **C2. Alternative rankings.** Both EEH cube 13 (hourly, full-time non-managerial adults, 3-digit) and ATO Table 15B (salary or wages by occupation and sex) are built. Both appear in the appendix sensitivity table. D4 decides which one appears in the note.
- **C3. Deciles.** Employment-weighted deciles from the EQ08 average of the May 2025, Aug 2025, Nov 2025 and Feb 2026 quarters. A unit that straddles a boundary is split fractionally. Each decile must hold 10% ± 0.5 pp of employment (tested).
- **C4. Coverage.** The share of pooled EQ08 employment, after nfd allocation, in v1.2 units with at least one non-missing linked SOC. The target is 98% or more. The unmatched list is published whether or not the target is met.
- **C5. Primary comparator.** JSA automation exposure, the measure DEWR (2026) uses. JSA augmentation and Eloundou et al. beta are shown alongside it, and AIOE only in aggregate.
- **C6. What counts as holding.** For a decile profile: the OLS slope of the decile means has the same sign under each variant, and the Spearman correlation of the decile means with the primary specification is at least 0.7. For the gap: its sign in the top and bottom quintiles is the same under every weighting scheme.
- **C7. Reporting.** Every specification in the sensitivity table (scheme × grade × ranking) is published, including those that do not hold.
- **C8. Small cells.** Set on 25 Oct 2026, before any WA result was produced. EQ08 publishes no RSEs, so the rule uses size instead. In WA charts and tables, a sub-major group with pooled WA employment below 5,000 is not shown on its own; it is grouped as "other sub-major groups (each under 5,000 in WA)". Its contribution still counts in the WA total. No WA × sex cells are produced.
- **C9. Decile layout.** Set on 25 Oct 2026, before any decile result was produced.
  - Deciles are formed once per sample and earnings ranking, over all units with an earnings value, and stay fixed across weighting schemes.
  - Decile means use the units that have a value under the scheme in question, and the employment they cover is reported.
  - Decile intensity is mean exposure divided by mean extensive margin, so exposure = extensive margin × intensity at decile level.
- **C10. Owner-manager sensitivity.** A draft list of owner-operator units (`R/fn_owner_managers.R`) is used for the exclusion run. It is a judgement list awaiting Luc's approval (D9), because ABS publishes form of employment only by occupation major group (Working Arrangements, Aug 2025, Table 4).

## Method notes

### N1. What produces the exact zeros in `job_exposure.csv` (M1, 25 Oct 2026)

Source: the appendix to Massenkoff and McCrory (2026), pages 2-4 and notes 1-3 (`data/raw/docs_ref/`, sha256 in MANIFEST). The formulas in the PDF are images, so the steps below come from the appendix text, not from the equations.

- **Count gate.** A task counts as covered only if its usage reaches at least 100. Usage here is work-related Claude.ai conversations plus all first-party API traffic for that task. In the previous two AEI samples (2M Claude.ai and 2M API transcripts), 100 is about 0.0025% of traffic. Tasks below the gate get exposure 0.
- **Work-use filter.** Claude.ai conversations count only if the use-case classifier labels them work-related; coursework and personal use are dropped. API calls all count.
- **Capability gate.** Each task is multiplied by an indicator for Eloundou et al. (2023) beta above zero (beta of 0.5 is upgraded to 1). A task that is not theoretically doable with an LLM gets 0 however much it is used.
- **Automation weight.** Tasks that pass both gates are scaled by a factor between 0.5 (augmentation only, no API use) and 1 (automation only).
- **Job level.** Job exposure is the time-share-weighted sum of task exposure. Time shares come from Tamkin and McCrory (2025). A job is exactly zero when none of its tasks passes both gates.
- **Shared tasks.** Identical or near-identical tasks shared by several occupations have their counts split across those occupations by employment shares.

**Consequence for this project.** A zero means the job's tasks fell below the usage gate in the sample, or none of the used tasks passed the capability gate. It does not mean no use. Zeros are flagged as "below usage threshold" in every display. SOC codes with no row (111 of 867) are treated as missing, not zero.

### N2. Profile of `job_exposure.csv` (M1, 25 Oct 2026)

The file matches the brief. It has 756 rows and no duplicate codes. 411 values are exactly 0 (54.4%). The maximum is 0.745, the mean 0.077 and the median 0. There are no missing values. These counts are fixed in `tests/testthat/test-01-job-exposure.R`.

Known artefacts, flagged for the note:

| SOC | Title | observed_exposure |
|---|---|---|
| 43-6012 | Legal Secretaries and Administrative Assistants | 0.000 |
| 23-2011 | Paralegals and Legal Assistants | 0.293 |
| 35-3011 | Bartenders | 0.000 |
| 41-2031 | Retail Salespersons | 0.322 |
| 23-1011 | Lawyers | 0.167 |

`task_penetration.csv` has 17,998 rows: task text and penetration, with no occupation code. It joins to O*NET by task text.

### N3. Earnings sources at 4-digit (M1, 25 Oct 2026)

No EEH May 2025 cube gives hourly earnings at 4-digit:

| Cube | Content | Occupation level |
|---|---|---|
| 11 | Weekly total cash earnings, all employees, with standard errors | 4-digit (364 units) |
| 13 | Hourly earnings, full-time non-managerial adults | 3-digit (99 units) |
| 4-7 | Hourly earnings | Major group only |

Under C1, the primary ranking is therefore cube 11, persons. Results:

- 342 of the 364 EEH units are published.
- After bridging, 339 of 358 v1.2 units have a direct value. The other 19 take the employment-weighted mean of their published siblings in the same minor group, listed in `data/out/m2/earnings_imputation_log.csv`.
- 25 v1.2 units have an RSE above 25%. They are dropped in the planned sensitivity run.
- For units bridged from several EEH units, the RSE used is the largest among the sources.

### N4. ANZSCO 2022 to v1.2 bridge (M2, 25 Oct 2026)

EEH and ATO use 2021/2022 unit groups. The bridge runs 2022 → 2021 → v1.3 at 6-digit (ABS correspondence tables), then rolls up to unit groups. v1.3 has exactly the v1.2 codes, so that last step is the identity (`data/interim/check_v13_vs_v12.csv`).

Of the 369 unit-pair links:

- 337 keep the same code.
- 5 are one-to-one recodes. These are the farm worker groups: 8421, 8422, 8423, 8424 and 8431 map back to 8411, 8412, 8415, 8416 and 8413.
- 14 are merges, 7 are splits and 6 are many-to-many.

The changes involve 1215-1217 → 1212/1214, 3625-3627 → 3622, 3633 → 3612/3999, 843x → 8414/8419, plus 2233, 2254/2341/2345, 2346/2349 and 2611/2632. The full table is in `data/interim/bridge_2022units_v12units.csv`.

Merge weights are ATO 2023-24 individual counts for each 2022 unit group. Neither EEH nor EQ08 gives counts at 2022 unit-group level, so these are the only counts available. A v1.2 unit fed by several 2022 units takes their weighted mean; a split passes the same value to each v1.2 unit.

### N5. ATO Table 15B lookup (M2, 25 Oct 2026)

ATO Table 15B lists 429 4-digit codes:

- 361 are ANZSCO 2022 unit groups. These are bridged as in N4.
- 68 have no ANZSCO unit group: 0000 "Occupation blank", "type not specified" codes such as 2330 and 5300, and ATO-specific codes such as the APS-level public servant codes 5310 and 5610.

Those 68 codes hold 23.1% of individuals; 20.0% are blank. The full lookup is in `data/out/m2/ato_code_lookup.csv`.

The ATO ranking uses average salary or wage income. Averages, unlike medians, combine exactly across merged units. The median is kept as a check. One v1.2 unit is imputed from its minor group.

### N6. Vintage of the comparison measures (M2, 25 Oct 2026)

- **Eloundou et al.** `occ_level.csv` uses O*NET-SOC 2019 codes; all 923 are in O*NET 31.0. They are averaged to SOC 2018 6-digit codes with equal weights, which covers 798 of 867 SOC codes. The GPT-4 rating (`dv_rating_beta`) is the primary Eloundou measure and the human rating a check. Massenkoff and McCrory's capability gate uses Eloundou's task-level beta, so this comparison is partly mechanical, as the brief says.
- **AIOE and LM-AIOE** use SOC 2010 codes: 774 codes, including 15-1132 and not 15-1252. They enter the chain at the SOC 2010 step and are kept only in `data/interim/` under a NOT_FOR_PUBLICATION file name.
- **JSA.** `Occupations_8.csv` has 714 rows, of which 357 are "All occupations" rows. Each has a unique code, and all are valid v1.2 codes. The one v1.2 unit without a JSA score is 6399 Other Sales Support Workers.
- **Global automation share** comes from the AEI 2026-06-26 GLOBAL rows at soc_occupation level 0. Those rows are O*NET-SOC codes, pooled to SOC 6-digit across April and May and weighted by usage share. 441 SOC codes have a published share.

### N7. Scheme 4 links (M2, 25 Oct 2026)

The JSA/LMI correspondence mixes unit-group and occupation rows. A unit's links are the union of both, rolled up to SOC 2018 6-digit codes; rows graded NONE are dropped. The result is 712 unit-SOC pairs: 349 GOOD, 320 ACCEPTABLE and 43 POOR (the strongest grade is kept per pair). 354 of 358 units are linked; the exceptions are 1113, 1392, 4411 and 6399. A sensitivity check drops POOR-only links.

### N8. EQ08 nfd allocation (M1, 25 Oct 2026)

Over the four pooled quarters, nfd codes hold 1.8% to 2.6% of employment. Each nfd code is allocated to the unit groups under it, pro rata within each quarter × sex × state cell. One case had all children at zero in its cell: 3240 nfd, 0.74 persons on average. It used national shares for the same quarter and sex. Pooled employment is 14.673 million, and 1.661 million in WA. The log is in `data/out/m1/eq08_nfd_allocation_log.csv`.

### N9. Influence of single large units (added after the first M3 results, 25 Oct 2026)

This check was not part of the method fixed before results. It was added after seeing that scheme 4 was the only scheme whose decile profile did not hold, and it is reported as a post-results addition. For each scheme, the top-minus-bottom gap is recomputed with each of the five largest units in deciles 1 and 10 left out in turn (`data/out/m3/influence_largest_units.csv`).

One unit moves the result: 6211 Sales Assistants (General), with 3.9% of employment, most of it in decile 1.

- Under scheme 4 it links only to US Retail Salespersons (41-2031, usage-based exposure 0.32). That is one of the artefacts flagged in the brief.
- Leaving it out moves scheme 4's top-minus-bottom gap from -2.4 to +7.8 pp.
- Under schemes 1 to 3 it links to several SOCs. Leaving it out moves the gap from 4.3 to 6.9 pp (scheme 1).

### N10. Concentration index for AIOE

AIOE is a standardised score with negative values, so CI = 2cov(e, r)/mean(e) is not meaningful for it. AIOE appears only in the correlations and in decile means of the rank gap, both of which are aggregate.

### N11. OEWS weights (M2, 25 Oct 2026)

OEWS May 2025 gives weights for SOC 2018 codes as follows:

- **818 of 867 codes** take their own detailed employment directly.
- **28 codes** that OEWS publishes only inside combined codes (e.g. 13-1020, 31-1120, 53-1047) share their broad group's residual employment equally.
- **2 codes** have no OEWS row at all: 11-1031 Legislators and 45-3031 Fishing and Hunting Workers. They get the smallest published detailed employment in their SOC major group, so they still count but carry little weight.
- **The 19 military codes (55-xxxx)** have no weight. None of them has usage-based exposure.

Every source is recorded in `data/interim/soc_weights_oews.csv`.

### N12. Scheme 3 title matching (M2, 25 Oct 2026)

Title-match-first is applied to each v1.2 occupation, not each unit, so that one matched occupation does not drop the rest of its unit.

- A link matches when the token sets of the two titles are equal, or their Jaccard similarity is at least 0.75. Tokens are lower-cased, a short stop-word list is removed, and simple plurals are reduced.
- 150 occupations in 81 units have a match.
- All matches are listed in `data/out/m2/scheme3_title_matches.csv` for review.

### N13. Primary chain against the 2022-path validation chain (M2, 25 Oct 2026)

The primary chain links all 358 units to SOC 2018 codes: 2,438 unit-SOC links through 429 ISCO units. The validation chain (ISCO-08 → 2022 → 2021 → v1.3) gives identical SOC sets for 350 of 358 units.

The 8 that differ are 1212, 2254, 2341, 2345, 3321, 4111, 8415 and 8419, all units touched by the 2021/2022 changes. Details are in `data/out/m2/chain_validation_primary_vs_2022path.csv`.

Coverage under C4 is 99.1% of pooled employment, against the 98% target. Three units are unmatched; the largest is 4221 Education Aides, whose linked SOCs (25-904x) have no row in `job_exposure.csv`.

Grades: 59 units are one-to-one (13.5% of employment), 155 few-to-one (47.1%), 141 diffuse (38.5%) and 3 unmatched.

### N14. AEI SOC major-group shares do not sum to 100

The published `pct` shares for SOC major groups sum to the following:

| Geography | April 2026 | May 2026 | Groups published |
|---|---|---|---|
| AUS | 97.6% | 98.9% | All 22 |
| GLOBAL | 94.6% | 98.7% | All 22 |
| AU-WA | 97.5% | 98.7% | 18-19 |

For AUS and GLOBAL, the shortfall therefore is not suppression of whole groups. The data documentation does not say what fills it, so it is reported as a limitation. The usage index uses the published shares as they stand.

### N15. Checks closed before drafting the note (M4, 25 Oct 2026)

- **JSA (2025), *Our Gen AI Transition*, pages 35-36.** JSA discusses Handa et al. (2025) and notes the study's Claude.ai focus (under 3% of Australian market share, as JSA reports it) and its global sample. JSA says an ANZSCO replication would cover only a small share of AI users and would depend on mapping conversations to tasks, but would be valuable for future monitoring. The note paraphrases this and cites the page.
- **ABS, "Upcoming changes to Labour Force Survey outputs" (19 Mar 2026).** EQ08 is among the detailed tables not published from April 2026 onwards. ABS intends to resume occupation data coded to OSCA from the September 2026 reference period, and does not state the level of detail.
- **ABS, Labour Force, Australia methodology, September 2026 (published 15 Oct 2026).** Its history of changes records that OSCA coding has been implemented. It does not say which occupation levels are published.
- **Wording.** The note says only what these sources state. It says nothing on whether unit-group detail will return.

### N16. Rendering and the prose checker (M4, 25 Oct 2026)

**Rendering.** The project folder's name contains colons (`~:Projects:ai-wage-distribution`), which break Quarto's stylesheet compiler. `make note` (`R/render.sh`) therefore renders in a temporary copy at a colon-free path, using the project's renv library, and copies the outputs back to `note/_rendered/` and `docs/_rendered/`. Typst will not read files outside the document's folder, so the memo's figures and bibliography are copied into the temporary tree.

**Prose checker (`R/check.R`).** It now ignores markup that is not prose: citation keys, Quarto attribute blocks, maths, numbered-list markers, and "scheme N" labels (treated like figure labels). Its rule on bare digits and causal words is unchanged.

**Numbers in the documents.** Every number in the note, appendix and memo comes from `data/out/note_facts.csv` (`R/13_facts.R`) or is read directly from pipeline output.

### N17. Occupation explorer (M5, 25 Oct 2026)

`explorer/index.html` is a single static page in plain JavaScript; no chart library is needed. It loads `explorer/explorer_units.json`, which has one row per v1.2 unit (358) and the same fields as `data/out/explorer_units.csv`. It has no AIOE field.

Each unit shows:

- usage-based exposure to two decimal places, with a band (the employment-weighted fifth it falls in) and a "below usage threshold" flag on zeros;
- the range across the four weighting schemes;
- the extensive margin;
- JSA automation and augmentation, and Eloundou beta;
- the global Claude.ai automation share;
- employment (Australia and WA) and EEH weekly earnings;
- the crosswalk grade and the contributing US occupations with their scheme 1 weights.

`tests/explorer_check.py` (Playwright) checks that:

- the JSON has one row per unit;
- every displayed field is a CSV column;
- the disclaimer is visible;
- the page does not scroll sideways at 375 px with every unit expanded;
- search by code and by title works.

It passed on 25 Oct 2026. The screenshot is `explorer/check_375px.png`.

### N18. Optional extension G: rebuilding observed exposure from task data (25 Oct 2026)

`R/15_replicate_g.R` rebuilds occupation scores from the published task-level values (`task_penetration.csv`), joined to O*NET 31.0 task statements by text (99.2% of O*NET task rows join). Massenkoff and McCrory's time-share weights (Tamkin and McCrory 2025) are not published, so three stand-ins were tried:

| Weights | Spearman with the published score |
|---|---|
| Equal | 0.871 |
| O*NET importance | 0.869 |
| Importance × relevance | 0.870 |

The rebuilt and published scores agree on which occupations are exactly zero for about 93% of the 756 SOC codes.

**The 0.9 target is not met.** The unpublished time weights are the likely reason, but this has not been tested. The result is reported as it stands (`data/out/g_replication.csv`); the main analysis uses the published scores unchanged.

### N19. Clean-clone reproducibility test (25 Oct 2026)

A fresh `git clone` of commit `66afec8` was tested at a colon-free path, with the updated `renv.lock`:

- `renv::restore()` ran first.
- `make all` re-downloaded all 27 scriptable inputs, and each matched its recorded sha256. It then rebuilt everything in 2 min 39 s and passed all 65 tests.
- `make check` passed.
- The key outputs are byte-for-byte identical to the working copy: decile profiles, gaps, sensitivity table, coverage, explorer data and note facts.

renv's "out-of-sync" warning came from `dbplyr`, which renv detects as used. It is now installed and recorded, and the warning is gone.

### N20. D10: automated review of the 40 largest units (26 Oct 2026, under D11)

`R/16_top40_checks.R` runs seven checks on each of the 40 largest units, which hold 46.4% of employment. Each flag gets a resolution and a reason in `data/out/m2/top40_units_review.csv`, marked "reviewed_by: Claude (automated checks)".

| Check | Rule | Units flagged |
|---|---|---|
| Unmatched | No linked SOC has a score | 1 |
| Zero | Score is exactly 0 (below the usage gate) | 4 |
| Diffuse | Five or more scored linked SOCs | 10 |
| Scheme range | Spread across the four schemes above 0.10 | 9 |
| Influence | Leaving the unit out moves the main top-minus-bottom gap by more than 1 pp, or the decile-profile Spearman falls below 0.9 | 6 |
| Artefact | A flagged artefact SOC carries at least 25% of the weight | 3 |
| Unscored majority | Over half of linked US employment has no score | 2 |
| Title | No title word in common with the highest-weight SOC | 11 |

**Resolution.** No mapping was edited by hand. The links come from official concordances, and the primary values were fixed before results.

- The 11 title flags were inspected one by one. Most are wording differences ("solicitor"/"lawyer", "child carer"/"childcare worker"), and each has a note in the table.
- **Two substantive issues came out of the review**, and both are now reported:
  - **6211 Sales Assistants (General).** Retail Salespersons, a flagged artefact, and Fast Food and Counter Workers carry four-fifths of its weight. It is the largest single influence on the main profile: leaving it out moves the top-minus-bottom gap by +2.6 pp.
  - **Units resting on a minority of their US counterparts.** 4221 Education Aides has none of its US counterparts scored. 4231 Aged and Disabled Carers has 95% of its linked US employment unscored (Home Health Aides and Personal Care Aides have no score).

**Added after the first results** (reported as such):

- the `unscored_weight_share` measure for every unit;
- a sensitivity sample excluding the 25 units (5.9% of employment) where it exceeds one half;
- this share as a column in the explorer.

The grid of specifications grows from 48 to 60.
