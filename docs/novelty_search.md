# Novelty search log (M0)

Project: *Usage-based AI exposure across Australia's earnings distribution: mapping US task-usage data onto ANZSCO occupations*
Maintainer: Luc Taya, Economics (Honours) graduate, University of Western Australia
Searches were run and screened under Luc Taya's direction. Luc Taya makes the kill/pivot call, which is recorded in `decision_log.md`.
Status: complete for the venues listed below. Six items need a manual check because the sites block scripted access (section 5).

## 1. Questions and decision rules

- **Q-A.** Has anyone mapped Anthropic Economic Index (AEI) usage data, or Massenkoff and McCrory's (2026) observed exposure, onto ANZSCO or ISCO-08?
- **Q-B.** Has anyone compared usage-based AI exposure with potential (capability-based) exposure for Australia, and in particular across the earnings distribution?
- **Q-C.** Does JSA, or a predecessor agency, publish an ANZSCO to O*NET-SOC correspondence?

Decision rules from the project brief:

- **(a)** A mapping by earnings exists but has no usage-potential gap: pivot to the gap and the WA composition angle, and cite that work as the base.
- **(b)** The gap by Australian earnings decile already exists: stop. Luc chooses between an extension framed as such and dropping the project.
- **(c)** JSA's Australian Skills Classification publishes an ANZSCO to O*NET-SOC mapping: add it as a fourth weighting scheme and use it to validate the BLS-ISCO-ABS chain.

## 2. Venues and how they were accessed

| Venue | Method | Access result |
|---|---|---|
| Google Scholar | Scripted requests to scholar.google.com, 2025 onward unless stated, at least 8 seconds apart | Worked for 12 queries. No CAPTCHA shown. |
| SSRN | Domain-restricted web search, plus Google Scholar listings | Abstract pages return HTTP 403 to scripts and a bot-verification page in a browser. Not bypassed. SSRN papers were seen only as search or Scholar snippets. |
| arXiv | export.arxiv.org API (title and abstract fields) | Worked. |
| RePEc/IDEAS | IDEAS search page, then web search restricted to ideas.repec.org and econpapers.repec.org | The IDEAS search page returned no result list to a script (the site reports heavy bot traffic). Domain-restricted search used instead. |
| NBER | Web search restricted to nber.org | Worked. |
| JSA, e61, UTS HTI, PC, RBA, Treasury, Grattan, ILO, OECD, BCEC, Melbourne Institute | Web search restricted to each domain, then direct reads of relevant pages and PDFs | Worked. |
| APO | Direct | HTTP 403. The same DEWR report was obtained from dewr.gov.au. |
| Labour Market Insights | Direct | labourmarketinsights.gov.au no longer resolves. Page read from the Internet Archive capture of 24 May 2024. |

How hits were read: Word and PDF files were converted to text and searched. HTML pages were read through an automated fetch-and-summarise tool. Each hit in section 4 says which, so the reader knows how much weight it carries.

## 3. Query log

"Screened" means the top results were read at title and snippet level.

### General web and institutional sites

| ID | Venue | Query | Result |
|---|---|---|---|
| Q01 | General web | `"Anthropic Economic Index" ANZSCO` | About 9 screened. No AEI to ANZSCO mapping. Found the `aieconindex` R package (H31), which is for data access only. |
| Q02 | General web | `"Anthropic Economic Index" Australia occupations earnings exposure` | About 9 screened. Found McCrory (2026), *How Australia uses Claude* (H6). |
| Q03 | General web | `Massenkoff McCrory "observed exposure" labor market impacts of AI` | Secondary coverage of the method paper only. |
| Q04 | General web | `Anthropic Economic Index ISCO-08 crosswalk occupations country` | 10 screened. Generic ISCO crosswalk resources only. |
| Q05 | General web | `Australia AI usage versus AI exposure occupations earnings decile Claude` | 9 screened. Found Gross (2026) (H3), DEWR (2026) via APO (H1), PwC AI Jobs Barometer 2026 Australia (H11) and Indeed Hiring Lab (2024). |
| Q06 | General web | `e61 "Missing the forest for the AI job cuts"` | Not found by general search. Found under Q09. |
| Q07 | General web | `e61 "What AI job loss predictions get wrong about technological change"` | Not found by general search. Found under Q10. |
| Q08 | General web | `e61 "AI versus the internet"` | Not found by general search. Found under Q12. |
| Q09 | e61.in | `e61 AI job cuts exposure occupations employment` | Gibbons (2025); Gibbons and Palan (2026) (H7). |
| Q10 | e61.in | `e61 AI job loss predictions technological change` | Gibbons and Palan (2026) (H7). |
| Q11 | e61.in | `e61 Anthropic Economic Index Claude usage occupations` | No e61 analysis of AEI data. The e61/UTS report *AI, Productivity, and Australia's Choice of Regulatory Framework* (Sep 2025) surfaced; it is not occupational. |
| Q12 | e61.in | `e61 AI internet adoption comparison` | Thomas (2026); Nolan and Rankin (2026) (H7). |
| Q13 | General web | `AI exposure most exposed fifth occupations employment grew 5.6% November 2022 February 2026 Australia` | DEWR (2026) (H1). |
| Q14 | General web | `Zac Gross working paper AI exposure Single Touch Payroll hiring occupations 2026` | Only the Substack summary of Gross (2026). The paper itself was not located. |
| Q15 | jobsandskills.gov.au | `Jobs and Skills Australia Anthropic Economic Index Claude usage occupations` | JSA (2025) *Our Gen AI Transition* discusses Handa et al. (2025) but does not replicate it (H5). |
| Q16 | General web | `Australian Skills Classification O*NET SOC mapping ANZSCO concordance` | Dickenson-Jones (2026) blog crosswalk (H30); the LMI ANZSCO to O*NET-SOC correspondence page (H28). |
| Q17 | General web | `Mason 2026 CSIRO generative AI exposure Australian employment occupations` | Mason et al. (2026), AJLE, on job ads 2020-23 (H9); DEWR announcement. |
| Q18 | grattan.edu.au | `Grattan Institute AI exposure occupations earnings Australia` | Commentary only. No analysis of exposure by earnings. |
| Q19 | pc.gov.au | `Productivity Commission AI exposure occupations wages generative AI` | PC (2025), *Making the most of the AI opportunity*, research paper 1. No exposure-by-earnings analysis found. |
| Q20 | rba.gov.au | `RBA AI exposure occupations wages labour market generative AI` | RBA Bulletin, Nov 2025, *Technology Investment and AI: What Are Firms Telling Us?* (firm liaison). No usage-by-occupation analysis. |
| Q21 | General web | `ANZSCO O*NET-SOC correspondence file download Jobs and Skills Australia` | LMI correspondence page (H28). |
| Q22 | jobsandskills.gov.au | `Australian Skills Classification O*NET correspondence` | ASC Release 2.0 report (2022) (H29). No current download of the concordance located on jobsandskills.gov.au. |
| Q23 | treasury.gov.au | `Treasury AI exposure occupations Australian workers earnings generative AI analysis` | Intergenerational Report 2026 (H8). |
| Q24 | uts.edu.au | `Human Technology Institute AI workers occupations exposure usage report` | Only HTI's 2023 report on the state of AI governance. Not occupational. |
| Q25 | ilo.org | `ILO generative AI exposure Anthropic Economic Index usage ISCO occupations comparison` | ILO WP140 (refined index), ILO Research Brief (Feb 2026) and ILO WP166. No AEI to ISCO comparison on ilo.org. |
| Q26 | oecd.org | `OECD generative AI actual use versus exposure occupations Anthropic Economic Index` | OECD work on potential exposure only (2024, 2025). |
| Q27 | General web | `Bankwest Curtin Economics Centre AI exposure Western Australia occupations jobs` | No BCEC AI-exposure report. Free and Harris (2026) (H4) and PwC Australia 2025 and 2026 surfaced. |
| Q28 | nber.org | `Anthropic Economic Index observed exposure occupations wages usage potential gap` | NBER w35110 on the stability of LLM exposure scores. No Australian work. |
| Q29 | ideas.repec.org, econpapers.repec.org | `Anthropic Economic Index Claude occupations exposure Australia ANZSCO` | Nothing Australian. |
| Q30 | bcec.edu.au | `BCEC artificial intelligence jobs Western Australia exposure report` | Nothing on AI exposure. BCEC's *Future of Work in Australia* is older and national. |
| Q31 | melbourneinstitute.unimelb.edu.au | `Melbourne Institute generative AI exposure occupations earnings Australia HILDA` | Only the title of a 2026 HILDA conference session (Seetahul) (H12). No paper located. |
| Q32 | ssrn.com | `Anthropic Economic Index observed exposure Australia occupations SSRN 2026` | Gong (2026), Sedai (2026), Yildirim (2026), Nandhakumar (2026), Fan and Nguyen (2026). None Australian in the snippets. |
| Q33 | General web | `"Aggregate Gains from AI and Their Distribution" Fan Nguyen IMF working paper usage data` | IMF WP/26/147 abstract on econpapers (H15). |
| Q34 | General web (extended) | `Australian occupations Anthropic observed exposure compared with Jobs and Skills Australia Gen AI scores by earnings or income distribution` | DEWR (2026) again, plus commercial blogs. No earnings breakdown. |
| Q35 | General web | `Seetahul "generative AI exposure" Australia ageing gender-segregated workforce HILDA` | ESRI WP808, on HILDA 2002-2022 with the Tolan et al. index (H10). Seetahul's paper not located. |
| Q36 | IDEAS search page | `"Anthropic Economic Index"` and five variants | No result list returned to a script (see section 2). |

### arXiv API

| ID | Query | Total | Notes |
|---|---|---|---|
| A01 | `all:"Anthropic Economic Index"` | 6 | 2608.17624 (Fábrega), 2606.01152, 2604.06906, 2602.17221, 2511.15080 (AEI report), 2510.23669 (Agarwal et al.). None maps to ANZSCO or ISCO, and none is Australian. |
| A02 | `all:ANZSCO` | 0 | |
| A03 | `all:"observed exposure" AND all:AI` | 0 | |
| A04 | `all:Australia AND all:"AI exposure"` | 0 | |
| A05 | `all:Claude AND all:ISCO` | 0 | |
| A06 | `all:"Economic Index" AND all:occupations AND all:usage` | 0 | |
| A07 | `abs:ANZSCO` | 0 | |
| A08 | `all:anzsco` | 0 | |
| A09 | `abs:Australia AND abs:"AI exposure"` | 0 | |
| A10 | `abs:Australia AND abs:exposure AND abs:occupations AND abs:AI` | 0 | |
| A11 | `abs:"Anthropic Economic Index" AND abs:countries` | 0 | |
| A12 | `abs:"usage" AND abs:"exposure" AND abs:Claude` | 5 | 2609.36129, 2607.15506 (Steele and Cruz, H27), 2607.19375, 2605.16699, 2404.00699. None Australian. |

Separate abstract look-ups (arXiv `id_list`): 2604.18849, 2605.21743, 2607.05404, 2606.26118, 2605.15474, 2510.23669, 2608.17624, 2507.07935, 2601.02554, 2608.00038 and 2607.15506.

### Google Scholar

| ID | Query | Count | Top results screened |
|---|---|---|---|
| G01 | `"Anthropic Economic Index" ANZSCO` (2025+) | 1 | Demirev (2026), SSRN 7054839 (H2). |
| G02 | `"Anthropic Economic Index" ISCO` (2025+) | 31 | Kansoy (2026) (H13); Murugan et al. (2026) (H14); Fan and Nguyen (2026), on SSRN and IMF (H15); Ren (2026); Yildirim (2026); Frånlund Johansson (2026); Permach and Peña (2026); Kumar (2026); Wang et al. (2026). |
| G03 | `"observed exposure" Massenkoff McCrory` (2025+) | 43 | AEI report *Cadences* (Jun 2026); Levkoff (2026) (H19); Renard (2026); Yang (2026); Nandhakumar (2026) (H23); Litowitz et al. (2026); Yildirim (2026); Korinek et al. (2026). |
| G04 | `"Anthropic Economic Index" Australia occupations` (2025+) | 32 | Fan and Nguyen; Fernandez et al. (AIES 2026) (H17); Ma and Bai; Demirev; Sverdlov; Iscenko et al. (2026), Google ATLAS (H16); Cicarelli; Wongchamcharoen et al. (NBER w35663); Bühler and Jelinek; El Kaissi. |
| G05 | `Claude usage "AI exposure" Australia earnings` (2025+) | 47 | Fan and Nguyen; Steele and Cruz; Murugan et al.; Demirev; Fernandez et al.; Iscenko et al.; Rice and Guerrini; Chandar and Klein Teeselink (41 countries); Hartley et al. |
| G06-G10 | Title look-ups for snippets: Demirev, Levkoff, Fan and Nguyen, Nandhakumar, and Demirev with ANZSCO | 1 each | Snippets are recorded in section 4. |
| G11 | `Gross 2026 "AI exposure" "Single Touch Payroll" Census occupations` (2025+) | 0 | |
| G12 | `allintitle: "AI exposure" Australia 2026 usage earnings` (2025+) | 0 | |

## 4. Relevant hits

Key to the "Read" column: **FT** means full text converted and searched; **Page** means an HTML page read by the fetch-and-summarise tool; **Abs** means abstract only; **Snip** means a search or Scholar snippet only.

### Australian work closest to this project

| # | Work | What it does | Q-A | Q-B | Read |
|---|---|---|---|---|---|
| H1 | DEWR (2026), *AI and employment in Australia: Monitoring framework and evidence to date*, July 2026, CC BY 4.0. PDF: https://www.dewr.gov.au/download/17666/ai-and-employment-australia/43205/ai-and-employment-australia/pdf. The Word version was read (sha256 `f69bfc2d…e3e6dd`). | Uses JSA automation scores in a PPML model of EQ08 employment, Feb 2015 to Feb 2026. Massenkoff-McCrory observed exposure is converted to ANZSCO 4-digit (SOC 2018, then O*NET-SOC 2010, then an ANZSCO correspondence table), using a simple average where a unit links to several scored US occupations, then standardised. 91 JSA-scored units were unmatched. It is used as a robustness measure, with a near-zero coefficient that is not significant. | **Yes** | **Partly**: top-5 lists for JSA, AIOE and observed exposure, and score distributions by task group. No earnings, wages or deciles (wages are excluded explicitly, and "Investigating the AI-wages relationship" is listed as future work). No WA. | FT |
| H2 | Demirev, G. (2026), "AI and the Composition of Labor Demand: Evidence from Online Job Postings", draft of 9 Sep 2026, SSRN 7054839 | Studies how EU (CEDEFOP) and Australian (JSA Internet Vacancy Index) job postings changed after ChatGPT, by occupational AI exposure. It uses five exposure measures, among them the Handa et al. (2025) usage score. It is not Massenkoff-McCrory observed exposure. Australian ANZSCO vacancies are merged to the scores through a crosswalk at ISCO three-digit level. There is no earnings or wage-distribution analysis and no usage-versus-potential comparison. | **Yes** (usage score to ANZSCO via ISCO) | **No** | FT (read in full, PDF supplied by Luc) |
| H3 | Gross, Z. (2026), working paper summarised in "Kookaburras in the Coal Mine?", *Gross National Product* (Substack), 2 Jun 2026 | Links Census 2021 occupation to Single Touch Payroll. Looks at earnings growth and hiring by occupational AI exposure. The post does not name the exposure measure. DEWR cites it as Gross (2026). | Unknown | No sign of it | Page (**manual check**) |
| H4 | Free, C. and Harris, L. (2026), *The Wired Belt: Where AI Could Reshape Australian Politics*, University of Sydney Business School | An electorate index combining JSA, ILO and AIOE (all potential measures) at ANZSCO 4-digit, weighted by Census occupation mix. Compared with household income across electorates. | No (no usage measure) | No | FT |
| H5 | JSA (2025), *Our Gen AI Transition: Implications for Work and Skills* | Discusses Handa et al. (2025). Notes Claude.ai's small Australian market share and its global sample, and says replicating the analysis on ANZSCO would capture only a small share of Australian activity. No replication. | No | No | Snip (read in full in M1) |
| H6 | McCrory, P. (2026), *How Australia uses Claude: Findings from the Anthropic Economic Index*, Anthropic, 31 Mar 2026 | Australian Claude.ai use by state (AUI) and by task mix at SOC major group. No ANZSCO, no earnings, no comparison with potential exposure. WA is among the lowest AUIs. | No | No | Page |
| H7a | Gibbons, T. (2025), *Missing the forest for the AI job cuts*, e61, 31 Oct 2025 | Employment and job-posting trends for high- versus low-exposure occupations. The exposure measure is not named. | No | No | Page |
| H7b | Gibbons, T. and Palan, A. (2026), *What AI job loss predictions get wrong about technological change*, e61, 22 May 2026 | Argues for moving beyond simple exposure metrics (automation, productivity and new-task channels). No usage data and no earnings. | No | No | Page |
| H7c | Thomas, H. (2026), *AI versus the internet*, e61, 10 Jul 2026 | Bank-transaction data on paid AI subscriptions by income quintile. This is the only Australian measure of actual AI use by income found. It is not occupational. | No | No | Page |
| H7d | Nolan, M. and Rankin, E. (2026), *Taxing robots: the good news and risks about AI and government revenue*, e61, 7 Aug 2026 | Revenue scenarios that assume any AI wage decline is equal across the income distribution. No occupational exposure. | No | No | Page |
| H8 | Treasury (2026), *Intergenerational Report 2026* (Sep 2026) | Cites McCrory (2026) on Australian Claude use. No occupational usage analysis found. | No | No | FT (searched) |
| H9 | Mason, C. et al. (2026), *Australian Journal of Labour Economics* (CSIRO) | Firm AI adoption and job ads, 2020-23. Not usage-based exposure. | No | No | Snip |
| H10 | ESRI Working Paper 808 | HILDA 2002-2022 with the Tolan et al. index (a potential measure). | No | No | Snip |
| H11 | PwC (2026), *AI Jobs Barometer: Australia* | PwC's own exposure measure, job postings and wage premia. Not usage-based. | No | No | Snip |
| H12 | Seetahul, S. (2026), HILDA conference session, "Mapping generative AI exposure across Australia's ageing and gender-segregated workforce" | Session title only. | Unknown | Unknown | Snip (**manual check**) |

### International work mapping AEI data to other classifications (Q-A)

| # | Work | What it does | Read |
|---|---|---|---|
| H13 | Kansoy, F. (2026), *Measuring AI Use across Countries and Occupations*, University of Oxford, 11 Sep 2026 | Allocates AEI country-level consumer shares (Apr-May 2026, 121 countries and areas) to ISCO through ESCO-O*NET links, with weights normalised so totals are preserved. Records unpublished mass. Compares results with ILO, Eloundou and Felten scores. Earnings sensitivities use Eurostat SES and UK ASHE. Case countries are Germany, France and the UK. No Australian analysis found in the text. | FT (searched) |
| H14 | Murugan, A. et al. (2026), *The Jagged Global Economy*, arXiv 2607.05404 | National exposure for 141 countries from occupation scores and ISCO employment. Validated against AEI, Microsoft and OpenAI adoption at country level. | Abs |
| H15 | Fan, R. Y. and Nguyen, H. M. (2026), *Aggregate Gains from AI and Their Distribution: Global Evidence from Usage Data*, IMF WP/26/147 | Five AEI waves. An AI concentration index by country and a labour-cost equivalent. No within-country earnings distribution is mentioned in the abstract. | Abs |
| H16 | Iscenko, Z. et al. (2026), *Google's AI & Economy ATLAS v1.0*, arXiv 2608.00038 | Gemini usage mapped to more than 800 occupations and 150 countries. Non-Anthropic usage data. | Abs |
| H17 | Fernandez, M. et al. (2026), AIES proceedings, gendered analysis | Uses AEI data. Scholar listing only. | Snip |

### US comparisons of usage with potential (the gap concept)

| # | Work | What it does | Read |
|---|---|---|---|
| H18 | Massenkoff, M. and McCrory, P. (2026), *Labor market impacts of AI*, Anthropic, 5 Mar 2026 | Observed exposure, and observed coverage against theoretical coverage. | Snip (appendix to be read in M1) |
| H19 | Levkoff, S. (2026), SSRN working paper 7217958, draft V4 (Sep 2026) | US only (OEWS May 2024).<br>- Observed exposure rises with wages (Spearman 0.29); the top wage quintile's mean (0.105) is nearly three times the bottom's (0.038).<br>- The correlation with Eloundou beta (0.705) is almost entirely produced by the capability gate. A permutation null gives 0.673.<br>- Within the capability envelope, use is associated with teleworkability, not with wages.<br>- Detailed occupation rankings churn across AEI vintages (agreement 0.58), while major-group structure is stable (0.85).<br>- No Australian or ANZSCO analysis. | FT (read in full, PDF supplied by Luc) |
| H20 | Sedai, A. (2026), *Exposure Is Not Adoption*, SSRN 7533251 | Usage-based adoption against exposure. Ranks are similar but levels diverge. | Snip |
| H21 | Gong, X. (2026), *Exposure, Task Length and the Channel of AI Use*, SSRN 7574859 | Exposure indices against task-level usage. | Snip |
| H22 | Yildirim, A. H. (2026), SSRN 7363301 | Reach and direction of occupational exposure. | Snip |
| H23 | Nandhakumar, S. (2026), *The Frontline Exposure Gap*, SSRN 7162039 | AEI usage in frontline service occupations. | Snip |
| H24 | Tomlinson, K. et al. (2025), *Working with AI*, arXiv 2507.07935 | Usage-based applicability from Copilot. Weak correlation with wages. | Abs |
| H25 | Yin, M. and Ogut, B. (2026), *Who Uses AI? Platform Selection and the Measurement of Occupational AI Exposure*, arXiv 2605.21743 | Platform user selection in usage-based exposure. Reweighting to BLS shares attenuates estimates. Relevant to the limitations section. | Abs |
| H26 | Henseke, G. (2026), *From Exposure to Adoption*, arXiv 2604.18849 | Survey adoption against exposure in 35 European countries. | Abs |
| H27 | Steele, J. L. and Cruz, I. (2026), arXiv 2607.15506 | Anthropic and OpenAI query data, salaries and exposure. | Abs |

### Crosswalk resources (Q-C)

| # | Resource | Notes | Read |
|---|---|---|---|
| H28 | Labour Market Insights (National Skills Commission), *ANZSCO 2013 to O*NET-SOC 2019* correspondence, `labourmarketinsights.gov.au/media/pmukn3qt/anzsco-2013-to-onet-soc-2019.xlsx` | The page says LMI displays ANZSCO 2013 Version 1.3, but the file's own Notes sheet says it is coded to ANZSCO 2013 Version 1.2 (checked in M1). The page was last updated on 27 Mar 2023, and the site was archived when JSA was created. The live site no longer resolves. The Internet Archive capture of the file returns HTTP 200 (393,024 bytes). Not yet downloaded or inspected, and the licence is not verified. | Page (archived) |
| H29 | National Skills Commission (2022), *Australian Skills Classification Release 2.0* | The ASC was built from O*NET through an O*NET-SOC to ANZSCO concordance. | Snip (read in M1) |
| H30 | Dickenson-Jones, G. (2026), "The boring part first: Building a crosswalk from O*NET-SOC to ANZSCO", 21 Aug 2026 | O*NET-SOC to ESCO, ISCO and then ANZSCO, using ABS OSCA tables. Built for job-transition work, not AI exposure. | Page |
| H31 | Coverdale, C. (2026), `aieconindex` R package v0.2.0 (MIT) | Access to AEI data. No ANZSCO. | Page |

## 5. Items needing a manual check

These could not be read in full because of bot verification, or because the paper was not located. Suggested steps, to run in a normal browser:

1. ~~**Demirev (2026)**~~ **Read in full.** It maps a usage score to ANZSCO for Australian job postings. It has no earnings analysis and no usage-potential gap.
2. ~~**Levkoff (2026)**~~ **Read in full.** It is US only. It reports a wage-quintile gradient of observed exposure and shows the Eloundou correlation is mechanical. There is no Australian analysis.
3. **Sedai (2026)**, SSRN 7533251, and **Gong (2026)**, SSRN 7574859. Any non-US coverage?
4. **Gross (2026)**. Which exposure measure does the working paper use? Is it usage-based?
5. **Seetahul (2026)**, the HILDA conference paper. Which measure, and is earnings in scope?
6. ~~**JSA (2025)**, *Our Gen AI Transition*. Confirm the passage on replicating the AEI with ANZSCO.~~ **Done.** Report pages 35-36 discuss Handa et al. (2025). They say that replicating it for Australia with ANZSCO would still cover only a small share of AI users, that the strength of its estimates would depend on mapping conversations to tasks, and that such analysis would be valuable for future monitoring.

Scholar queries worth rerunning by hand later: `"observed exposure" ANZSCO`, `"Anthropic Economic Index" Australia earnings`, `"usage-based" "AI exposure" Australia`.

## 6. Assessment against the decision rules

The decision is Luc Taya's and is recorded in `decision_log.md`.

- **(b) is not triggered on the evidence found.** No work found reports usage-based exposure, or a usage-potential gap, by Australian earnings decile. The residual risk sits in items 1 and 2 of section 5.
- **(a) is not triggered as written**, because no Australian mapping by earnings was found. But DEWR (2026) already maps observed exposure onto ANZSCO 4-digit units and compares it with JSA in a limited way. So the project cannot claim the first AEI-to-ANZSCO mapping. The novelty claim narrows to five things: the usage-potential gap across the Australian earnings distribution; the extensive and intensive margins; the WA composition decomposition; the split by sex; and crosswalk-grade sensitivity. DEWR (2026) would be cited as the base for the mapping, and the US usage-versus-capability papers (H18-H24) as the base for the gap concept.
- **(c) is partly triggered.** The National Skills Commission published an ANZSCO 2013 (v1.3) to O*NET-SOC 2019 correspondence on Labour Market Insights. It is not branded as part of the Australian Skills Classification, and it now survives only as an Internet Archive capture.

**Decision (Luc Taya):** continue with the narrowed novelty claim and cite DEWR (2026) as the mapping base. See D1 in `decision_log.md`.

**Update, after reading Demirev and Levkoff in full:** rule (b) is still not triggered. Neither paper reports usage-based exposure, or a usage-potential gap, across Australian earnings deciles.

The claim is narrowed and cited as follows:

- **Mapping.** DEWR (2026) and Demirev (2026) have both already mapped AEI usage-based scores onto ANZSCO, so the project claims no first mapping.
- **Gap concept.** Levkoff (2026) is the closest US work on usage against capability and on the wage gradient. It is cited for the gap concept, and for quantifying how much of the agreement with Eloundou et al. is mechanical.
- **What is new.** The descriptive comparison across the Australian earnings distribution, with the margins, sex and WA composition.
