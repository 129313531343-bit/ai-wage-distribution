# Draft charts for the note and appendix, drawn only from data/out/m3/ script output.
# Static images for the PDF/HTML note (the explorer is the interactive view).
# Colours: the reference palette in the dataviz guidance (light mode). Slots 1-3 are the
# subset validated for all-pairs use; single-series charts use slot 1 only.
# Titles describe what is plotted; they carry no takeaway (takeaways are Luc's).

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
  library(ggplot2)
  library(ggrepel)
})
source("R/utils.R")

fig_dir <- file.path(project_root(), "note", "figures")
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)
m3 <- function(f) read_codes_csv(out_path("m3", f))

pal <- c(blue = "#2a78d6", orange = "#eb6834", aqua = "#1baf7a")
ink <- list(primary = "#0b0b0b", secondary = "#52514e", muted = "#898781", grid = "#e1e0d9",
            axis = "#c3c2b7", surface = "#fcfcfb", neutral = "#c3c2b7")

theme_note <- function() {
  theme_minimal(base_size = 10, base_family = "Helvetica") +
    theme(
      plot.background = element_rect(fill = ink$surface, colour = NA),
      panel.background = element_rect(fill = ink$surface, colour = NA),
      panel.grid.major = element_line(colour = ink$grid, linewidth = 0.3),
      panel.grid.minor = element_blank(),
      axis.line.x = element_line(colour = ink$axis, linewidth = 0.3),
      axis.text = element_text(colour = ink$muted),
      axis.title = element_text(colour = ink$secondary),
      plot.title = element_text(colour = ink$primary, face = "bold", size = 11),
      plot.subtitle = element_text(colour = ink$secondary),
      plot.caption = element_text(colour = ink$muted, hjust = 0, size = 7.5),
      strip.text = element_text(colour = ink$primary, face = "bold", hjust = 0),
      plot.title.position = "plot", plot.caption.position = "plot",
      legend.position = "top", legend.justification = "left",
      legend.text = element_text(colour = ink$secondary), legend.title = element_blank()
    )
}
save_fig <- function(p, name, w = 7, h = 4.2) {
  ggsave(file.path(fig_dir, paste0(name, ".png")), p, width = w, height = h, dpi = 200, bg = ink$surface)
}
caption_src <- "Usage-based exposure: US task-level Claude.ai use (Massenkoff and McCrory 2026) mapped to ANZSCO v1.2 units.\nEarnings deciles: EEH May 2025, employment-weighted with EQ08 (May 2025 to Feb 2026)."
decile_axis <- scale_x_continuous(breaks = 1:10, name = "Earnings decile (1 = lowest, EEH weekly earnings)")
pot_labels <- c(jsa_automation = "JSA automation exposure", jsa_augmentation = "JSA augmentation exposure",
                beta_gpt4 = "Eloundou et al. beta (GPT-4 rating)")

# 1. Usage-potential rank gap by decile, with the range across weighting schemes ---------------
gaps <- m3("gap_by_decile.csv") |> filter(sample == "all", ranking == "eeh", potential %in% names(pot_labels))
g1 <- gaps |>
  group_by(potential, decile) |>
  summarise(lo = min(gap_rank), hi = max(gap_rank), primary = gap_rank[scheme == "s1"], .groups = "drop") |>
  mutate(potential = factor(pot_labels[potential], levels = pot_labels))
p1 <- ggplot(g1, aes(decile)) +
  geom_hline(yintercept = 0, colour = ink$axis, linewidth = 0.4) +
  geom_linerange(aes(ymin = lo, ymax = hi), colour = "#9ec5f4", linewidth = 2.2) +
  geom_line(aes(y = primary), colour = pal["blue"], linewidth = 0.7) +
  geom_point(aes(y = primary), colour = pal["blue"], size = 1.8) +
  facet_wrap(~potential, nrow = 1) +
  decile_axis +
  labs(title = "Usage-potential rank gap by earnings decile",
       subtitle = "Percentile rank of usage-based exposure minus percentile rank of each potential measure.\nLine: scheme 1 (primary). Bar: range across the four weighting schemes.",
       y = "Rank gap (percentile points)", caption = caption_src) +
  theme_note()
save_fig(p1, "fig1_gap_by_decile", w = 8, h = 4)

# 2. Exposure, extensive margin and intensity by decile (three panels, no dual axis) -------------
dp <- m3("decile_profiles.csv") |> filter(scheme == "s1", sample == "all", ranking == "eeh") |>
  select(decile, usage, extensive, intensity) |>
  pivot_longer(-decile) |>
  mutate(name = factor(name, levels = c("usage", "extensive", "intensity"),
                       labels = c("Usage-based exposure", "Extensive margin", "Intensity")))
p2 <- ggplot(dp, aes(decile, value)) +
  geom_col(fill = pal["blue"], width = 0.7) +
  facet_wrap(~name, nrow = 1, scales = "free_y") +
  decile_axis +
  labs(title = "Usage-based exposure, extensive margin and intensity by earnings decile",
       subtitle = "Scheme 1 (OEWS employment weights). Employment-weighted decile means. Extensive margin: weighted share of\nlinked US occupations with any measured use. Intensity: exposure divided by the extensive margin.", y = NULL, caption = caption_src) +
  theme_note()
save_fig(p2, "fig2_margins_by_decile", w = 8, h = 3.8)

# 3. Concentration curves ---------------------------------------------------------------
cc <- m3("concentration_curves.csv") |> filter(measure %in% c("usage", "jsa_automation", "beta_gpt4"))
cc_lab <- c(usage = "Usage-based exposure", jsa_automation = "JSA automation exposure", beta_gpt4 = "Eloundou et al. beta")
cc <- cc |> mutate(measure = factor(cc_lab[measure], levels = cc_lab))
ci <- m3("concentration_indices.csv")
ends <- cc |> group_by(measure) |> filter(abs(cum_emp - 0.6) == min(abs(cum_emp - 0.6))) |> slice(1) |> ungroup()
p3 <- ggplot(cc, aes(cum_emp, cum_exposure, colour = measure)) +
  geom_abline(slope = 1, intercept = 0, colour = ink$axis, linewidth = 0.4) +
  geom_step(linewidth = 0.7) +
  scale_colour_manual(values = unname(pal)) +
  scale_x_continuous(labels = scales::percent, name = "Cumulative share of employment, lowest to highest earnings") +
  scale_y_continuous(labels = scales::percent, name = "Cumulative share of exposure") +
  coord_equal() +
  labs(title = "Concentration curves by earnings",
       subtitle = sprintf("Concentration index: usage-based %.2f, JSA automation %.2f, Eloundou beta %.2f.\nCurves below the diagonal mean exposure is concentrated among higher earners.",
                          ci$ci[ci$measure == "usage"], ci$ci[ci$measure == "jsa_automation"], ci$ci[ci$measure == "beta_gpt4"]),
       caption = caption_src) +
  theme_note()
save_fig(p3, "fig3_concentration_curves", w = 6, h = 6.2)

# 4. Rank scatter of usage against JSA automation, largest disagreements labelled ------------
units <- read_codes_csv(interim_path("unit_measures_long.csv")) |> filter(scheme == "s1", measure == "usage_exposure") |>
  select(unit, usage = score)
emp <- read_codes_csv(interim_path("emp_units.csv")) |> select(unit, title, emp)
jsa <- read_codes_csv(interim_path("jsa_units.csv")) |> select(unit, jsa_automation)
source("R/fn_analysis.R")
sc <- emp |> inner_join(units, by = "unit") |> inner_join(jsa, by = "unit") |> filter(!is.na(usage), !is.na(jsa_automation))
sc <- sc |> mutate(pr_usage = 100 * weighted_rank(usage, emp), pr_jsa = 100 * weighted_rank(jsa_automation, emp))
dis <- m3("largest_disagreements_jsa.csv")
sc <- sc |> mutate(label = if_else(unit %in% dis$unit, title, NA_character_))
p4 <- ggplot(sc, aes(pr_jsa, pr_usage)) +
  geom_abline(slope = 1, intercept = 0, colour = ink$axis, linewidth = 0.4) +
  geom_point(aes(size = emp), colour = pal["blue"], alpha = 0.45, stroke = 0) +
  geom_point(data = filter(sc, !is.na(label)), aes(size = emp), shape = 21, fill = pal["blue"], colour = ink$surface, stroke = 0.6) +
  geom_text_repel(aes(label = label), size = 2.5, colour = ink$secondary, min.segment.length = 0, segment.colour = ink$axis,
                  max.overlaps = Inf, seed = 1, na.rm = TRUE) +
  scale_size_area(max_size = 7, guide = "none") +
  scale_x_continuous(limits = c(0, 100), name = "Percentile rank, JSA automation exposure") +
  scale_y_continuous(limits = c(0, 100), name = "Percentile rank, usage-based exposure") +
  coord_equal() +
  labs(title = "Usage-based exposure against JSA automation exposure, by unit group",
       subtitle = "Employment-weighted percentile ranks; point area shows employment. Units with zero usage-based\nexposure share one tied rank. Labelled: the 15 largest rank disagreements whose sign is the same\nunder all four weighting schemes.",
       caption = caption_src) +
  theme_note()
save_fig(p4, "fig4_rank_scatter_jsa", w = 7, h = 7.4)

# 5a. Women and men by decile -----------------------------------------------------------
sx <- m3("sex_deciles.csv") |> select(decile, Women = women, Men = men) |> pivot_longer(-decile)
p5a <- ggplot(sx, aes(decile, value, colour = name)) +
  geom_line(linewidth = 0.7) + geom_point(size = 1.8) +
  scale_colour_manual(values = c(Women = unname(pal["blue"]), Men = unname(pal["orange"]))) +
  geom_text(data = filter(sx, decile == 10), aes(label = name), hjust = -0.25, size = 3, colour = "#52514e", show.legend = FALSE) +
  decile_axis + expand_limits(x = 10.8) +
  labs(title = "Usage-based exposure of women and men by earnings decile",
       subtitle = "Deciles from the persons earnings ranking; means weighted by each sex's employment.",
       y = "Usage-based exposure", caption = caption_src) +
  theme_note()
save_fig(p5a, "fig5a_sex_by_decile", w = 7, h = 4)

# 5b. WA decomposition by major group ------------------------------------------------------
v12 <- read_codes_csv(interim_path("v12_units.csv"))
major_names <- c(`1` = "Managers", `2` = "Professionals", `3` = "Technicians and Trades Workers",
                 `4` = "Community and Personal Service Workers", `5` = "Clerical and Administrative Workers",
                 `6` = "Sales Workers", `7` = "Machinery Operators and Drivers", `8` = "Labourers")
wa <- m3("wa_decomposition.csv") |> filter(level == "major", measure == "usage") |>
  mutate(group_name = factor(major_names[group], levels = rev(major_names)))
wa_tot <- m3("wa_vs_national.csv") |> filter(measure == "usage")
p5b <- ggplot(wa, aes(contribution * 100, group_name)) +
  geom_vline(xintercept = 0, colour = ink$axis, linewidth = 0.4) +
  geom_col(fill = pal["blue"], width = 0.6) +
  labs(title = "WA minus national usage-based exposure, by occupation major group",
       subtitle = sprintf("Contribution = (WA employment share - national share) x unit exposure, summed within group.\nMean exposure: WA %.1f, Australia %.1f, difference %.1f (all x 100). The difference is occupation mix only, by construction.",
                          100 * wa_tot$mean_wa, 100 * wa_tot$mean_aus, 100 * wa_tot$wa_gap),
       x = "Contribution to WA minus national (exposure x 100)", y = NULL,
       caption = "Usage-based exposure: US task-level Claude.ai use (Massenkoff and McCrory 2026) mapped to ANZSCO v1.2 units.\nEmployment shares: EQ08, average of May 2025 to Feb 2026.") +
  theme_note()
save_fig(p5b, "fig5b_wa_decomposition", w = 7, h = 4)

# 6. SOC major-group usage index for AU, AU-WA and GLOBAL ------------------------------------
ui <- m3("soc_major_usage_index.csv") |> filter(!is.na(usage_index))
ord <- ui |> filter(geo_id == "AUS") |> arrange(usage_index) |> pull(node_name)
ui <- ui |> mutate(node_name = factor(node_name, levels = unique(c(ord, setdiff(unique(ui$node_name), ord)))),
                   geo = factor(geo_id, levels = c("AUS", "AU-WA", "GLOBAL"), labels = c("Australia", "Western Australia", "Global (US employment base)")))
p6 <- ggplot(ui, aes(usage_index, node_name, colour = geo)) +
  geom_vline(xintercept = 1, colour = ink$axis, linewidth = 0.4) +
  geom_point(size = 2.2, position = position_dodge(width = 0.6)) +
  scale_colour_manual(values = unname(pal)) +
  scale_x_log10(name = "Usage share / employment share (log scale; 1 = proportional)") +
  labs(title = "Claude.ai usage relative to employment, by SOC major group",
       subtitle = "Usage shares are conversation-task shares (AEI, Apr-May 2026), not users' jobs. Australian employment is EQ08\nallocated to SOC with scheme 1 weights; the global row uses US OEWS employment.",
       y = NULL, caption = "Source: Anthropic Economic Index 2026-06-26 release; ABS EQ08; BLS OEWS May 2025.\nSuppressed cells are omitted.") +
  theme_note()
save_fig(p6, "fig6_major_group_usage_index", w = 7.5, h = 6.5)

# Appendix A1. Global automation share by decile --------------------------------------------
ga <- m3("decile_profiles.csv") |> filter(scheme == "s1", sample == "all", ranking == "eeh")
pa1 <- ggplot(ga, aes(decile, global_automation)) +
  geom_col(fill = pal["blue"], width = 0.7) + decile_axis +
  labs(title = "Global Claude.ai automation share by earnings decile",
       subtitle = "Share of conversations classed as automation (global Claude.ai, not Australian), scheme 1.",
       y = "Automation share (%)", caption = caption_src) +
  theme_note()
save_fig(pa1, "figA1_global_automation_by_decile", w = 7, h = 3.8)

# Appendix A2. All units against non-diffuse units ---------------------------------------------
gr <- m3("decile_profiles.csv") |> filter(scheme == "s1", ranking == "eeh", sample %in% c("all", "non_diffuse")) |>
  mutate(sample = factor(sample, levels = c("all", "non_diffuse"), labels = c("All units", "Non-diffuse units (1-4 linked SOCs)")))
pa2 <- ggplot(gr, aes(decile, usage, colour = sample)) +
  geom_line(linewidth = 0.7) + geom_point(size = 1.8) +
  scale_colour_manual(values = unname(pal[1:2])) + decile_axis +
  labs(title = "Usage-based exposure by decile: all units and non-diffuse units",
       subtitle = "Scheme 1. Deciles re-formed within each sample.", y = "Usage-based exposure", caption = caption_src) +
  theme_note()
save_fig(pa2, "figA2_grade_restricted", w = 7, h = 4)

message("Charts written to note/figures/")
