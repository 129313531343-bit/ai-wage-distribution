# Usage-based AI exposure across Australia's earnings distribution

*Mapping US task-usage data onto ANZSCO occupations*

Luc Taya, Economics (Honours) graduate, University of Western Australia

> **Status: working draft v0.9, comments welcome.**

**Read it:** [website](https://129313531343-bit.github.io/ai-wage-distribution/) · [note (HTML)](https://129313531343-bit.github.io/ai-wage-distribution/note/_rendered/note.html) · [note (PDF)](note/_rendered/note.pdf) · [appendix](note/_rendered/appendix.pdf) · [occupation explorer](https://129313531343-bit.github.io/ai-wage-distribution/explorer/) · [summary](docs/_rendered/summary.pdf) · [methods memo](docs/_rendered/methods_memo.pdf) · [explainer](docs/explainer.md)

The data behind this project are task-level Claude.ai and first-party API use by self-selected users of one provider, classified to US occupational tasks. No Australian occupational AI use is measured. The usage-based exposure scores describe tasks in US occupations and are applied to Australian occupation mixes. Where the source data have Australian rows, those rows classify the task in a conversation, not the user's job. Every result is shown next to at least one measure that does not come from Anthropic.

**Descriptive; not a job-loss or career-risk score; not advice.**

## Question

How is measured AI use, captured by usage-based exposure, distributed across Australia's earnings distribution? And where does it run ahead of, or behind, measures of what AI could do? The comparison measures are Jobs and Skills Australia's automation and augmentation scores and Eloundou et al.'s beta, plus AIOE in aggregate only.

The project goes from "could be used" to "is being used". It does not go to labour-market outcomes, and it makes no causal claims.

## What is new

DEWR (2026) and Demirev (2026) have already mapped Anthropic usage-based scores onto ANZSCO. Levkoff (2026) compares observed and capability-based exposure for US occupations. This project adds:

- the usage-potential gap across Australian earnings deciles, with concentration indices that compare measures on ranks;
- the extensive margin and intensity;
- Western Australia's occupation-mix difference from the national picture, and results by sex;
- a graded crosswalk with four weighting schemes and every specification reported.

See `docs/novelty.md` and the search log in `docs/novelty_search.md`.

## Main specification and alternatives

Results in the body of the note use one specification, fixed before any result was produced:

- weighting scheme 1 (US employment weights);
- all 358 ANZSCO v1.2 unit groups;
- EEH weekly earnings for the ranking;
- JSA automation as the primary comparator.

The appendix reports every alternative: four weighting schemes, three earnings rankings and five samples, 60 specifications in all, including those that do not hold. It also reports an influence check and a top-40 unit review. Checks added after the first results are labelled as such. Every choice and its reason are in `decision_log.md`.

## Reproducing

1. Install R 4.5 and run `renv::restore()` in the project folder.
2. The three BLS inputs, which BLS blocks scripts from downloading, are committed in `data/raw/manual/`. Their sources:
   - https://www.bls.gov/soc/2018/soc_2010_to_2018_crosswalk.xlsx
   - https://www.bls.gov/soc/ISCO_SOC_Crosswalk.xls
   - https://www.bls.gov/oes/special-requests/oesm25nat.zip
3. `make all` fetches the other inputs, checks them against `data/raw/MANIFEST.csv`, builds every table and runs the tests. `make check` adds the publication checks.
4. `make note` renders the note, appendix, methods memo and summary with Quarto 1.10.
5. Optional Python checks (`pip install -r tests/requirements.txt`):
   - `make explorer-check` tests the explorer at 375 px with Playwright;
   - `make theory-check` verifies the theory section with sympy.

A fresh clone reproduces every published output byte for byte (decision log N19).

## Website

`index.html` is a landing page linking the note, appendix, summary, methods memo and explorer. It is published with GitHub Pages: Settings → Pages → Deploy from a branch → `main`, folder `/` (root). The empty `.nojekyll` file stops GitHub from hiding the `_rendered` folders.

## Repository layout

| Path | Contents |
|---|---|
| `data/raw/` | Raw files, never edited. `MANIFEST.csv` records each file's source URL, access date, sha256 and licence. |
| `data/interim/`, `data/out/` | Built tables. Published outputs live in `data/out/`. |
| `R/`, `tests/` | Pipeline code and tests. |
| `theory/` | Symbolic and numerical checks of the theory section. |
| `note/` | The research note and appendix (Quarto), with rendered HTML and PDF in `note/_rendered/`. |
| `explorer/` | Static occupation explorer. |
| `docs/` | Novelty search, summary, methods memo, explainer and credits. |
| `decision_log.md` | Decisions, method choices and method notes. |

## Contributions and AI use

- **Luc Taya** chose the topic and data sources and set the project's direction and decisions. Luc reviewed the first draft (v0.9) in a written review of 58 items and wrote a revised draft of the note: its structure, framing, literature and key findings.
- **Claude Code**, an AI coding assistant, wrote the analysis code. It drafted the first version's framing, takeaways and theory section, and its data, methods, limitations and appendix sections. It then checked Luc's review and revised draft against the pipeline and the cited sources, added the analyses the review asked for, and turned the revised draft into the current note. Changes from Luc's revision are listed in `decision_log.md` (D13).
- Luc reviewed and approved the final text.
- The planned code walk-throughs were replaced by a written explainer (`docs/explainer.md`).
- Every decision, and whether it was made before or after results were seen, is recorded in `decision_log.md`.
- No funding.

The data analysed are published by Anthropic, and the pipeline was written with Claude Code, an Anthropic product. Anthropic had no role in this project and has not reviewed or endorsed it.

## Data and credits

Every source, with its URL, access date, sha256 and licence, is in `data/raw/MANIFEST.csv`. Required credit lines are in `docs/credits.md`. Third-party data keep their own licences. AIOE values carry no licence and are not redistributed.

## Licence

Code: MIT (`LICENSE`). Text, figures and derived tables written for this project: CC BY 4.0 (`LICENSE-CONTENT.md`).
