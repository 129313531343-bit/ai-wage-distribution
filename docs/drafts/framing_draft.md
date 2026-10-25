<!-- DRAFT by Claude Code for Luc to edit (decision D8). Written after the first M3 results. Not for publication as is. Takeaways and interpretation are Luc's; section 3 lists figures only. -->

# Research question and framing (draft)

## 1. Research question

**Main question.** Across Australia's earnings distribution, where does measured AI use run ahead of, or behind, measured AI potential?

**Supporting questions**

1. How does usage-based exposure vary across employment-weighted earnings deciles? How much of that variation is the extensive margin (whether linked occupations show any measured use), and how much is intensity?
2. Decile by decile, how do occupations' ranks on usage-based exposure differ from their ranks on potential measures? The potential measures are JSA automation and augmentation exposure and Eloundou et al. beta, with AIOE in aggregate only.
3. How do these patterns differ between women and men? How much of WA's difference from the national average comes from its occupation mix alone?

## 2. Framing (draft paragraphs)

**What is measured.** The usage-based exposure scores come from US task-level Claude.ai use by self-selected users of one product (Massenkoff and McCrory 2026). No Australian occupational AI use is measured. The scores describe tasks in US occupations, are crosswalked to Australian unit groups, and are weighted by Australian employment. The Australian rows in the source data classify the task in a conversation, not the user's job. The work is descriptive. It is not a job-loss or career-risk score, and it is not advice.

**Where it sits.** DEWR (2026) already converts this measure to ANZSCO unit groups and uses it as an alternative to JSA's automation scores in a model of employment. It does not examine earnings. e61 (Gibbons and Palan, 22 May 2026) argues for moving beyond exposure metrics. This project goes part of the way: from what AI could be used for to what it is being used for. It does not go to labour-market outcomes. e61's revenue scenarios (Nolan and Rankin, 7 August 2026) assume any AI wage effect is spread evenly across the income distribution. This project describes how usage-based exposure is spread across earnings deciles. It makes no forecast.

**Why the gap and not just the gradient.** The usage-based measure is gated on Eloundou et al.'s beta: a task counts only if beta is above zero. So comparing it with Eloundou beta compares use with feasibility inside the same task frame, and is partly mechanical. JSA's scores and AIOE are the independent checks. The decile gradient of usage-based exposure is reported as context. The headline is how the ranks differ.

**What the method adds.** It splits usage-based exposure into the extensive margin and intensity. It grades every unit by how many US occupations feed it. It reruns everything under four crosswalk weighting schemes and on non-diffuse units only. Several of the patterns do not hold under every variant, and the note reports which (section 4).

## 3. Figures from the M3 outputs, for your takeaways

All figures come from `data/out/m3/` (primary specification: scheme 1, all units, EEH weekly ranking, unless stated).

- **Coverage.** 99.1% of pooled employment is in units with usage-based exposure (355 of 358 units). The unmatched units are 4221 Education Aides, 6392 Retail and Wool Buyers and 1392 Senior Non-commissioned Defence Force Members (`data/out/unmatched_units.csv`).
- **Decile profile.** Usage-based exposure averages 0.069 in decile 1 and 0.111 in decile 10, a top-minus-bottom gap of 4.3 pp. The profile is not monotonic; the peak is decile 7 at 0.192.
- **Extensive margin.** It rises from 0.39 in decile 1 to 0.81 in decile 10 (+42.6 pp). Intensity ranges from 0.13 to 0.28 and does not rise or fall steadily across deciles.
- **Concentration indices** (positive means concentrated among higher earners):

  | Measure | Concentration index |
  |---|---|
  | Usage-based exposure | 0.089 |
  | Extensive margin | 0.097 |
  | JSA automation | 0.013 |
  | JSA augmentation | 0.037 |
  | Eloundou beta | 0.116 |

- **Rank gap by quintile** (usage-based minus potential, percentile points; bottom quintile, top quintile):

  | Potential measure | Bottom quintile | Top quintile | Same sign under all four schemes? |
  |---|---|---|---|
  | JSA automation | -5.1 | +3.8 | Top only. The bottom is negative under schemes 1-3 and +1.6 under scheme 4. |
  | JSA augmentation | +7.7 | -10.8 | Yes, both ends |
  | Eloundou beta | +8.4 | -8.5 | Yes, both ends |

- **Unit-level rank correlations with usage-based exposure** (employment-weighted Spearman):

  | Measure | Correlation |
  |---|---|
  | JSA automation | 0.72 |
  | JSA augmentation | 0.64 |
  | Eloundou beta | 0.77 |
  | AIOE | 0.79 |

- **Largest disagreements with JSA automation** (sign holds under all schemes). Units ranked far lower on usage than on JSA automation include 5911 Purchasing and Supply Logistics Clerks, 5912 Transport and Despatch Clerks, 7321 Delivery Drivers, 5513 Payroll Clerks and 1411 Cafe and Restaurant Managers. Units ranked far higher include 2113 Photographers, 3422 Electrical Distribution Trades Workers and 2114 Visual Arts and Crafts Professionals. The full list is in `largest_disagreements_jsa.csv`.
- **Women and men.** Mean usage-based exposure is 0.142 for women and 0.100 for men. On JSA automation it is 0.404 and 0.346. Women's exposure is higher in every decile (`sex_deciles.csv`).
- **WA.** Mean usage-based exposure is 0.107 in WA and 0.120 nationally, a difference of -1.4 (× 100). By construction this is occupation mix only. Professionals contribute -0.96 of it (WA employment share 25.2% against 27.8% nationally). Technicians and Trades Workers contribute +0.05. JSA automation (-1.2) and Eloundou beta (-1.7) also show negative WA differences.
- **Usage index by SOC major group** (AU, AU-WA, global; `soc_major_usage_index.csv`). The published major-group shares sum to 97.6-98.9% for AUS (all 22 groups published), 97.5-98.7% for AU-WA (18-19 groups published) and 94.6-98.7% for GLOBAL (`aei_major_group_missing_mass.csv`). The AUS and GLOBAL shortfall is therefore not suppression; the AEI documentation does not say what fills it. This needs a line in the limitations section.

## 4. Where the robustness rule (C6) fails

- 27 of the 48 decile-profile specifications hold against the primary.
- **Scheme 4.** 2 of 12 hold. N9 shows that one unit, 6211 Sales Assistants (General), accounts for this: under scheme 4 it links only to US Retail Salespersons, a flagged artefact. Leaving it out moves scheme 4's top-minus-bottom gap from -2.4 to +7.8 pp.
- **ATO ranking.** The scheme 1 profile does not hold (Spearman 0.62 with the primary profile).
- **Non-diffuse units.** The gradient is steeper (top-minus-bottom 9.6 pp under scheme 1) and the profile holds.
- **JSA automation gap.** It fails the quintile sign test at the bottom end (see section 3).

## 5. Decisions still open

- D4: which alternative ranking (EEH cube 13 or ATO 15B) goes in the note. Both are in the appendix.
- D9: approve or edit the draft owner-manager list (`R/fn_owner_managers.R`).
- D10: sign off the 40 largest units (`data/out/m2/top40_units_review.csv`, with the empty `luc_signoff` and `luc_note` columns).

## References

- DEWR (2026), *AI and employment in Australia: Monitoring framework and evidence to date*.
- Gibbons, T. and Palan, A. (2026), "What AI job loss predictions get wrong about technological change", e61 Institute, 22 May.
- Massenkoff, M. and McCrory, P. (2026), "Labor market impacts of AI: A new measure and early evidence".
- Nolan, M. and Rankin, E. (2026), "Taxing robots: the good news and risks about AI and government revenue", e61 Institute, 7 August.
