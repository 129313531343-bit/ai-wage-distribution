# Usage-based AI exposure across Australia's earnings distribution

*Mapping US task-usage data onto ANZSCO occupations*

Luc Taya, Economics (Honours) graduate, University of Western Australia

> **Status: M3 (analysis drafted).** The crosswalk, the analyses A-D and the draft charts are built. Nothing here is final; the note is not yet written.

## Reproducing

1. Install R 4.5 and run `renv::restore()` in the project folder.
2. Download these three files by hand into `data/raw/manual/` (BLS blocks scripted downloads):
   - https://www.bls.gov/soc/2018/soc_2010_to_2018_crosswalk.xlsx
   - https://www.bls.gov/soc/ISCO_SOC_Crosswalk.xls
   - https://www.bls.gov/oes/special-requests/oesm25nat.zip
3. Run `make all` to fetch the other inputs, build every table and run the tests. Run `make check` before publishing anything.

The data behind this project are US task-level Claude.ai use by self-selected users, from one product. No Australian occupational AI use is measured. The usage-based exposure scores describe tasks in US occupations and are applied to Australian occupation mixes. Where the source data have Australian rows, those rows classify the task in a conversation, not the user's job. Every result is shown next to at least one measure that does not come from Anthropic.

**Descriptive; not a job-loss or career-risk score; not advice.**

## Question

Across Australia's earnings distribution, where does measured AI use ("usage-based exposure") run ahead of or behind measured AI potential? The plain exposure gradient by earnings decile is reported as context. The headline is the gap between usage and potential.

The project goes from "could be used" to "is being used". It does not go to labour-market outcomes, and it makes no causal claims.

## What is new

See `docs/novelty.md` and the full search log in `docs/novelty_search.md`. The mapping of usage-based exposure onto ANZSCO builds on DEWR (2026).

## Repository layout

| Path | Contents |
|---|---|
| `data/raw/` | Raw files, never edited. `MANIFEST.csv` records each file's source URL, access date, sha256 and licence. |
| `data/raw/manual/` | Files that must be downloaded by hand because the source blocks scripts. |
| `data/interim/`, `data/out/` | Built tables. Published outputs live in `data/out/`. |
| `R/`, `tests/testthat/` | Pipeline code and tests. |
| `note/` | The research note (Quarto). |
| `explorer/` | Static occupation explorer. |
| `docs/` | Novelty search and memos. |
| `decision_log.md` | Decisions, method choices and method notes. |

## Contributions and AI use

- **Luc Taya** chose the topic and data sources, makes the judgement calls, edits the research question and framing (first drafted by Claude Code after the first results), and writes the interpretation and every takeaway.
- **Claude Code**, an AI coding assistant, writes the pipeline under Luc's direction. So far it has run the novelty search and drafted `docs/novelty.md`. Later it drafts the data, methods, limitations and appendix sections for Luc to edit.
- Luc reviews the code in three walk-throughs:

  | Walk-through | When | Status |
  |---|---|---|
  | 1 | End of M2 | Not yet held |
  | 2 | End of M3 | Not yet held |
  | 3 | End of M5 | Not yet held |

The data analysed are published by Anthropic, and the pipeline was written with Claude Code, an Anthropic product. Anthropic had no role in this project and has not reviewed or endorsed it.

## Data and credits

Sources, licences and required credit lines will be listed here once M1 is complete, matching `data/raw/MANIFEST.csv`.

This project is not affiliated with or endorsed by Anthropic or any other data provider.

## Licence

To be decided before the repository is made public.
