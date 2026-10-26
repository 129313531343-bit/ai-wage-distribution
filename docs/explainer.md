# Explainer: how the pipeline works, and likely interview questions

A plain-English guide to the project. Figures are from the v0.9 outputs, recorded in `data/out/note_facts.csv`.

## The pipeline in plain English

**1. Start with a score for US occupations.** Anthropic publishes a score called "observed exposure" for 756 US occupations. Anthropic classifies millions of Claude conversations into the US government's list of job tasks (O*NET). A task counts if it shows enough work-related use and is something a language model could plausibly do. Tasks used in an automating way count fully; tasks used to help a person count half. Each occupation's score is the time-weighted share of its tasks that count. More than half of occupations score exactly zero.

**2. Translate US occupations into Australian ones.** No official table links US to Australian occupations directly, so the pipeline chains official tables: US SOC 2018 → SOC 2010 → the international ISCO-08 → Australian ANZSCO v1.2. The result is 2,438 links between 358 Australian unit groups and US occupations, through 429 ISCO units.

**3. Average into each Australian occupation.** An Australian occupation's score is the average of its linked US occupations' scores. In the main version, each US occupation is weighted by its US employment. Three other weightings check that the choice doesn't drive the results:

- equal weights;
- title matches first;
- Jobs and Skills Australia's direct US-Australia table.

Each Australian occupation is graded by how many US occupations feed it. "Diffuse" units, fed by five or more, hold 38% of employment, and every result is rerun without them.

**4. Add Australian employment and earnings.**

- Employment comes from ABS Labour Force table EQ08, averaged over May 2025 to February 2026.
- Earnings come from the ABS Employee Earnings and Hours survey (weekly earnings, May 2025). It uses newer occupation codes, so a bridge table translates them back.
- Occupations with suppressed earnings take their 3-digit group's average; 19 units do.

**5. Sort into earnings deciles.** Occupations are ranked by earnings and split into ten groups, each holding exactly a tenth of employment. An occupation that straddles a boundary is split between groups.

**6. Compare usage with potential.** For each occupation, the pipeline ranks usage-based exposure and each potential measure against all other occupations, weighted by employment. It then takes the difference in percentile ranks:

| Measure | Source | Depends on Anthropic data? |
|---|---|---|
| JSA automation exposure | Jobs and Skills Australia | No |
| JSA augmentation exposure | Jobs and Skills Australia | No |
| Eloundou et al. beta | OpenAI researchers | No, but see below |

The Eloundou comparison is partly circular: Anthropic's score only counts tasks that Eloundou rates as feasible.

**7. Check everything.** The checks cover four schemes × three earnings rankings × five samples, which is 60 specifications.

- 65 automated tests cover counts, weights, coverage and decile sizes.
- A fresh copy of the repository reproduces every output byte for byte.
- Prose checks block causal wording.
- The theory box's maths is verified by computer algebra.

**8. Publish what didn't work.** This includes the specifications that fail the robustness rule, checks added after seeing results, and known oddities in the source scores.

## Fifteen likely interview questions

**1. What does "usage-based exposure" measure?**
The share of a US occupation's working time spent on tasks that Claude is observed doing in work contexts, with automation weighted above assistance. It is about use of one product by its users. It isn't adoption across the economy, and it isn't any Australian worker's use.

**2. Why not use Anthropic's Australian data directly?**
The Australian rows classify the task in each conversation, not the user's job. They are published only as shares, and they lack the work filter and automation weighting. I use them only at the broad occupation-group level, to compare usage shares with employment shares.

**3. How do you get from US to Australian occupations, and what does it lose?**
Through official concordances, via ISCO-08. ISCO is coarser than either end, so it blurs zeros into small positive values. That's why I grade each unit, rerun on non-diffuse units, and compare four weighting schemes and a second chain built through the 2022 tables. The second chain matches for 350 of 358 units.

**4. What is your main finding?**
Measured AI use rises with earnings: 0.069 in the bottom decile against 0.111 in the top, with a concentration index of 0.089. The rise is not steady. Most of the gradient is the extensive margin, the share with any measured use, which goes from 0.39 to 0.81. Against JSA augmentation and Eloundou, usage ranks low earners higher and high earners lower. Against JSA automation the signs flip, but not robustly at the bottom.

**5. Why percentile ranks rather than levels?**
The measures are on different scales: one is a share of time, JSA's are 0–1 ratings and Eloundou's are averaged task ratings. Comparing ranks asks whether usage puts an occupation higher or lower in the distribution than potential does. A z-score version is computed as a check.

**6. Isn't the Eloundou comparison circular?**
Partly. Anthropic's score only counts tasks Eloundou rates feasible. Levkoff (2026) shows most of the correlation between the two comes from that gate. I treat JSA and AIOE as the independent comparisons, and say so in the note.

**7. How robust is it?**

- 32 of 60 specifications reproduce the main decile profile under a rule fixed in advance.
- The non-diffuse units give a steeper gradient (+9.6 pp, against +4.3 pp in the main result).
- The JSA-based weighting scheme mostly fails, because of one unit. Sales Assistants (General), 3.9% of employment, links under that scheme only to US Retail Salespersons, a known artefact. Leaving it out turns −2.4 pp into +7.7 pp.

All of this is in the appendix.

**8. Why weekly earnings, which mix hours and pay?**
No ABS earnings series gives hourly pay at the 4-digit occupation level. The hourly series exists only at the 3-digit level, and I report it as an alternative; it gives a flatter gradient. The ATO ranking gives a steeper one, but its profile doesn't hold.

**9. What does the WA result mean?**
WA's average usage-based exposure is lower (0.107 against 0.120). By construction this is entirely occupation mix: every occupation carries the same national score. It mostly reflects WA's smaller share of professionals. It says nothing about whether WA workers in a given job use AI less.

**10. Why are women more exposed?**
Women work more in occupations with higher usage-based scores. That's 0.142 against 0.100 overall, and higher in every decile. It's an occupation-mix result, not a statement about individual women.

**11. Can you say AI will reduce jobs or wages for anyone?**
No. The note is descriptive. It shows where measured use sits in the earnings distribution, not what use does to employment, wages or hours. DEWR (2026) and others study outcomes. This complements them.

**12. How does this connect to your thesis?**
My thesis models the skill premium with ICT paired with skilled labour and machinery with unskilled. The theory box adds AI two ways:

- **as ICT-type capital:** this raises the premium when ICT is a relative complement of skilled labour, as the thesis finds;
- **as a substitute for skilled tasks:** this always lowers the premium.

The data show where AI is used, mostly in higher-earning occupations, which fits both channels. They can't tell which channel operates or what AI does to the premium.

**13. What would you do with better data?**

- Australian usage by occupation from a survey or several platforms.
- OSCA-coded employment once ABS publishes it.
- Census TableBuilder, to see how much earnings vary within occupations.

**14. How was AI used in this project, and how do you know the code is right?**
Claude Code wrote the analysis code and drafted the framing, takeaways and theory section under my direction, and I reviewed and approved them. The checks:

- 65 tests;
- a clean-clone rebuild with identical outputs;
- every number in the note pulled from script output rather than typed;
- a decision log recording each choice and whether it was made before or after seeing results;
- symbolic verification of the theory.

The data come from Anthropic, and the tool is an Anthropic product. Both are disclosed, and Anthropic had no role.

**15. What are the biggest weaknesses?**

- The usage data come from one product's self-selected users.
- The scores classify conversation tasks.
- The crosswalk is coarse.
- 25 units, holding 5.9% of employment, rest mostly on US occupations with no score.
- Anthropic's own detailed rankings shift between data vintages.

The note lists each of these and reports the results with and without the affected units.
