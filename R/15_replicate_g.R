# Optional extension G: rebuild occupation-level observed exposure from the published task-level
# values (task_penetration.csv) and compare with job_exposure.csv. Target: Spearman >= 0.9.
# The time-share weights used by Massenkoff and McCrory (Tamkin and McCrory 2025) are not
# published, so three stand-ins from O*NET 31.0 are tried: equal weights, task importance (IM),
# and importance x relevance (IM x RT). The result is logged whichever way it comes out.

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
  library(stringr)
})
source("R/utils.R")

norm <- function(x) str_squish(str_to_lower(x))
tp <- read_csv(raw_path("aei", "task_penetration.csv"), show_col_types = FALSE) |>
  mutate(key = norm(task)) |> group_by(key) |> summarise(penetration = mean(penetration), .groups = "drop")
ts <- read_csv(raw_path("onet", "task_statements.csv"), show_col_types = FALSE) |>
  transmute(onetsoc = `O*NET-SOC Code`, task_id = `Task ID`, key = norm(Task))
tr <- read_csv(raw_path("onet", "task_ratings.csv"), show_col_types = FALSE) |>
  filter(`Scale ID` %in% c("IM", "RT")) |>
  select(onetsoc = `O*NET-SOC Code`, task_id = `Task ID`, scale = `Scale ID`, value = `Data Value`) |>
  pivot_wider(names_from = scale, values_from = value)
je <- read_csv(raw_path("aei", "job_exposure.csv"), show_col_types = FALSE) |> transmute(soc = occ_code, observed = observed_exposure)

tasks <- ts |>
  left_join(tp, by = "key") |>
  left_join(tr, by = c("onetsoc", "task_id")) |>
  mutate(soc = substr(onetsoc, 1, 7))
join_rate <- mean(!is.na(tasks$penetration))

score <- function(w) {
  tasks |>
    mutate(w = w) |>
    filter(!is.na(penetration), !is.na(w), w > 0) |>
    group_by(onetsoc, soc) |>
    summarise(s = sum(w * penetration) / sum(w), .groups = "drop") |>
    group_by(soc) |>
    summarise(rebuilt = mean(s), .groups = "drop")
}
variants <- list(
  equal = rep(1, nrow(tasks)),
  importance = tasks$IM,
  importance_x_relevance = tasks$IM * tasks$RT / 100
)
res <- bind_rows(lapply(names(variants), function(v) {
  d <- score(variants[[v]]) |> inner_join(je, by = "soc")
  tibble(weights = v, socs_compared = nrow(d),
         spearman = cor(d$rebuilt, d$observed, method = "spearman"),
         pearson = cor(d$rebuilt, d$observed),
         zero_agreement = mean((d$rebuilt == 0) == (d$observed == 0)),
         # Among occupations with a positive published score (added after the first results):
         # how much of the agreement comes from matching zeros.
         socs_nonzero = sum(d$observed > 0),
         spearman_nonzero = cor(d$rebuilt[d$observed > 0], d$observed[d$observed > 0], method = "spearman"))
})) |>
  mutate(task_text_join_rate = join_rate, target = 0.9, meets_target = spearman >= target)

write_csv(res, out_path("g_replication.csv"))
print(res)
