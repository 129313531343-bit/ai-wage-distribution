# Profile the AEI 2026-06-26 Claude.ai file for GLOBAL, AUS and AU-WA.
# Writes row counts by geography, month, category, level and metric type, and
# the sum of published SOC major-group shares (to show how much mass is suppressed).

suppressPackageStartupMessages({
  library(DBI)
  library(duckdb)
  library(readr)
})
source("R/utils.R")

con <- dbConnect(duckdb(shared_home = FALSE))
on.exit(dbDisconnect(con, shutdown = TRUE))
aei_file <- raw_path("aei", "aei_claude_ai_2026-06-26.csv")
dbExecute(con, sprintf(
  "CREATE VIEW aei AS SELECT * FROM read_csv_auto(%s, header = true)",
  dbQuoteString(con, aei_file)
))

geos <- "('GLOBAL', 'AUS', 'AU-WA')"

row_counts <- dbGetQuery(con, paste0("
  SELECT geo_id, strftime(date_start, '%Y-%m') AS period, category_name, hierarchy_level,
         CASE WHEN metric_id = 'pct' THEN 'pct' ELSE 'other' END AS metric_type,
         count(*) AS n_rows, count(DISTINCT node_name) AS n_nodes,
         count(DISTINCT metric_id) AS n_metrics
  FROM aei WHERE geo_id IN ", geos, "
  GROUP BY ALL ORDER BY geo_id, period, category_name, hierarchy_level, metric_type"))

major_group_mass <- dbGetQuery(con, paste0("
  SELECT geo_id, strftime(date_start, '%Y-%m') AS period, hierarchy_level,
         count(*) AS n_nodes, sum(value) AS pct_sum
  FROM aei
  WHERE geo_id IN ", geos, " AND category_name = 'soc_occupation' AND metric_id = 'pct'
  GROUP BY ALL ORDER BY geo_id, period, hierarchy_level"))

au_subregions <- dbGetQuery(con, "
  SELECT geo_id, strftime(date_start, '%Y-%m') AS period, count(*) AS n_rows
  FROM aei WHERE geo_id LIKE 'AU-%' GROUP BY ALL ORDER BY geo_id, period")

dir.create(out_path("m1"), recursive = TRUE, showWarnings = FALSE)
write_csv(row_counts, out_path("m1", "aei_row_counts.csv"))
write_csv(major_group_mass, out_path("m1", "aei_soc_published_mass.csv"))
write_csv(au_subregions, out_path("m1", "aei_au_subregion_rows.csv"))

print(as.data.frame(row_counts), row.names = FALSE)
print(as.data.frame(major_group_mass), row.names = FALSE)
print(as.data.frame(au_subregions), row.names = FALSE)
