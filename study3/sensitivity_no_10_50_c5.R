suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(lme4)
  library(lmerTest)
  library(emmeans)
})

output_dir <- "data/output"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

output_log <- file.path(output_dir, "sensitivity_no_10_50_output.txt")
output_table_md <- file.path(output_dir, "table_C5_no_10_50.md")

mood_col <- "2、请问您在参与本次实验过程中的情绪如何？&nbsp;"

clean_chr <- function(x) {
  x <- as.character(x)
  x <- trimws(gsub("[\t\r\n ]+", "", x))
  x[x == ""] <- NA
  x
}

map_attract <- function(raw_choice, mem) {
  rc <- clean_chr(raw_choice)
  out <- rep(NA_character_, length(rc))
  out[rc == "无区别"] <- "无区别"

  if (mem == "high") {
    out[rc == "图片2"] <- "有吸引力"
    out[rc == "图片1"] <- "无吸引力"
  } else {
    out[rc == "图片1"] <- "有吸引力"
    out[rc == "图片2"] <- "无吸引力"
  }
  out
}

extract_blocks <- function(df) {
  list(
    score_idx = (ncol(df) - 7):ncol(df),
    quality_idx = grep("请问您觉得此图片的拍摄质量如何", names(df), fixed = TRUE),
    attract_idx = grep("^吸引力", names(df))
  )
}

build_long_one <- function(df, participant_offset = 0L) {
  b <- extract_blocks(df)

  if (length(b$quality_idx) != 8 || length(b$attract_idx) != 4) {
    stop("Unexpected column structure in raw export. Check quality/attract blocks.")
  }

  score <- as.data.frame(df[, b$score_idx, drop = FALSE])
  colnames(score) <- c(
    "wine_high", "wine_low",
    "cake_high", "cake_low",
    "sandwich_high", "sandwich_low",
    "donut_high", "donut_low"
  )

  quality <- as.data.frame(df[, b$quality_idx, drop = FALSE])
  colnames(quality) <- c("q3", "q4", "q5", "q6", "q7", "q8", "q9", "q10")

  attract <- as.data.frame(df[, b$attract_idx, drop = FALSE])
  colnames(attract) <- c("a1", "a2", "a3", "a4")

  d <- bind_cols(score, quality, attract) %>%
    mutate(
      mood = clean_chr(df[[mood_col]]),
      participant = row_number() - 1L + participant_offset
    )

  mk <- function(type, mem, score_col, qual_col, attr_col) {
    tibble(
      participant = d$participant,
      type = type,
      memory_score = mem,
      score = suppressWarnings(as.numeric(d[[score_col]])),
      quality = clean_chr(d[[qual_col]]),
      attract = map_attract(d[[attr_col]], mem),
      mood = d$mood
    )
  }

  bind_rows(
    mk("wine", "high", "wine_high", "q10", "a1"),
    mk("wine", "low", "wine_low", "q5", "a1"),
    mk("cake", "high", "cake_high", "q7", "a2"),
    mk("cake", "low", "cake_low", "q4", "a2"),
    mk("sandwich", "high", "sandwich_high", "q8", "a3"),
    mk("sandwich", "low", "sandwich_low", "q9", "a3"),
    mk("donut", "high", "donut_high", "q3", "a4"),
    mk("donut", "low", "donut_low", "q6", "a4")
  )
}

fmt_num <- function(x, digits = 2) formatC(x, digits = digits, format = "f")
fmt_p <- function(p) {
  if (is.na(p)) return("")
  stars <- if (p < 0.001) "***" else if (p < 0.01) "**" else if (p < 0.05) "*" else if (p < 0.10) "†" else ""
  if (p < 0.001) return(paste0("< .001", stars))
  paste0(sub("^0\\.", ".", sprintf("%.3f", p)), stars)
}
row_line <- function(var, beta = "", se = "", p = "") {
  sprintf("  %-27s %-11s %-11s %s", var, beta, se, p)
}

# -------------------------------------------------------------------------
# 1) Read raw exports and apply only non-range exclusions (N should be 300)
# -------------------------------------------------------------------------
getwd()
na_raw <- read.csv(
  "data/input/naodao.csv",
  skip = 1,
  fileEncoding = "GBK",
  stringsAsFactors = FALSE,
  check.names = FALSE
)
ni_raw <- read.csv(
  "data/input/niming.csv",
  skip = 1,
  fileEncoding = "GBK",
  stringsAsFactors = FALSE,
  check.names = FALSE
)

ni_after_marker <- ni_raw[as.character(ni_raw[[ncol(ni_raw) - 2]]) != "，", , drop = FALSE]
ni_after_prefilter <- ni_after_marker[as.character(ni_after_marker[["1、您的年龄是多少？"]]) != "-999", , drop = FALSE]

removed_marker <- nrow(ni_raw) - nrow(ni_after_marker)
removed_age <- nrow(ni_after_marker) - nrow(ni_after_prefilter)

na <- na_raw
ni <- ni_after_prefilter

# Coerce score block numeric after prefilter
b_na <- extract_blocks(na)
b_ni <- extract_blocks(ni)
for (j in b_na$score_idx) na[[j]] <- suppressWarnings(as.numeric(na[[j]]))
for (j in b_ni$score_idx) ni[[j]] <- suppressWarnings(as.numeric(ni[[j]]))

long_df <- bind_rows(
  build_long_one(na, participant_offset = 0L),
  build_long_one(ni, participant_offset = nrow(na))
)

model_df <- long_df %>%
  filter(!is.na(score), !is.na(quality), !is.na(attract), !is.na(mood)) %>%
  mutate(
    participant = factor(participant),
    type = factor(type, levels = c("cake", "donut", "sandwich", "wine")),
    memory_score = factor(memory_score, levels = c("high", "low")),
    quality = factor(quality, levels = c("低质量", "中质量", "高质量")),
    attract = factor(attract, levels = c("无区别", "无吸引力", "有吸引力")),
    mood = factor(mood, levels = c("非常负面", "负面", "中立", "正面", "非常正面"))
  )

# -------------------------------------------------------------------------
# 2) Fit sensitivity model (no 10-50 range exclusion)
# -------------------------------------------------------------------------
fit <- lmer(
  score ~ memory_score * type + quality + attract + mood +
    (1 + memory_score | participant),
  data = model_df,
  REML = TRUE,
  control = lmerControl(optimizer = "bobyqa", optCtrl = list(maxfun = 2e5))
)

anova_tbl <- anova(fit)
coef_tbl <- as.data.frame(coef(summary(fit)))
coef_tbl$term <- rownames(coef_tbl)

emm_mem <- emmeans(fit, ~ memory_score)
emm_contrast <- as.data.frame(contrast(emm_mem, method = list("High - Low" = c(1, -1))))

paired_by_type <- long_df %>%
  select(participant, type, memory_score, score) %>%
  pivot_wider(names_from = memory_score, values_from = score) %>%
  mutate(diff = high - low) %>%
  group_by(type) %>%
  summarise(
    n_pairs = sum(!is.na(high) & !is.na(low)),
    mean_diff = mean(diff, na.rm = TRUE),
    p_value = ifelse(n_pairs > 1, as.numeric(t.test(high, low, paired = TRUE)$p.value), NA_real_),
    .groups = "drop"
  )

wide_overall <- long_df %>%
  select(participant, type, memory_score, score) %>%
  pivot_wider(names_from = memory_score, values_from = score) %>%
  mutate(diff = high - low) %>%
  group_by(participant) %>%
  summarise(mean_diff = mean(diff, na.rm = TRUE), .groups = "drop")

raw_mean_diff <- mean(wide_overall$mean_diff, na.rm = TRUE)
raw_paired_d <- raw_mean_diff / sd(wide_overall$mean_diff, na.rm = TRUE)

# -------------------------------------------------------------------------
# 3) Save full code output log
# -------------------------------------------------------------------------
log_header <- c(
  sprintf("Run timestamp: %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "Sensitivity specification: no 10-50 CNY range exclusion; keep original Niming prefilters.",
  "",
  "Participant flow counts:",
  sprintf("  Naodao raw: %d", nrow(na_raw)),
  sprintf("  Niming raw: %d", nrow(ni_raw)),
  sprintf("  Niming removed marker row (','): %d", removed_marker),
  sprintf("  Niming removed age == -999: %d", removed_age),
  sprintf("  Final participants for sensitivity model: %d", n_distinct(model_df$participant)),
  sprintf("  Final observations for sensitivity model: %d", nrow(model_df)),
  ""
)

log_body <- capture.output({
  cat("Model formula:\n")
  print(formula(fit))
  cat("\n=== Fixed + Random Effects Summary ===\n")
  print(summary(fit))
  cat("\n=== ANOVA (lmerTest) ===\n")
  print(anova_tbl)
  cat("\n=== Estimated Marginal Means (memory_score) ===\n")
  print(emm_mem)
  cat("\n=== High - Low Contrast ===\n")
  print(emm_contrast)
  cat("\n=== Raw Within-Participant Differences by Type ===\n")
  print(paired_by_type)
  cat("\nRaw overall within-participant mean difference (High - Low): ", raw_mean_diff, "\n", sep = "")
  cat("Raw paired Cohen's d: ", raw_paired_d, "\n", sep = "")
})

writeLines(c(log_header, log_body), con = output_log)

# -------------------------------------------------------------------------
# 4) Build manuscript-style Table C5 (Markdown)
# -------------------------------------------------------------------------
lookup <- function(term) {
  x <- coef_tbl %>% filter(term == !!term)
  if (nrow(x) == 0) return(c("", "", ""))
  c(fmt_num(x$Estimate, 2), fmt_num(x$`Std. Error`, 2), fmt_p(x$`Pr(>|t|)`))
}

vc <- as.data.frame(VarCorr(fit))
var_int <- vc %>% filter(grp == "participant", var1 == "(Intercept)") %>% slice(1)
var_slope <- vc %>% filter(grp == "participant", grepl("memory_score", var1)) %>% slice(1)
var_resid <- vc %>% filter(grp == "Residual") %>% slice(1)

table_lines <- c(
  "**Table C5. Sensitivity Analysis Without the 10-50 CNY Range Exclusion (Study 3, N = 300)**",
  "",
  "  --------------------------- ----------- ----------- ---------------------",
  "  Variable                    β           SE          p",
  "",
  row_line("Fixed effects"),
  "",
  {v <- lookup("(Intercept)"); row_line("Intercept", v[1], v[2], v[3])},
  "",
  row_line("Memorability score (ref:"),
  row_line("High)"),
  {v <- lookup("memory_scorelow"); row_line("Low", v[1], v[2], v[3])},
  "",
  row_line("Food type (ref: Cake)"),
  {v <- lookup("typedonut"); row_line("Donut", v[1], v[2], v[3])},
  {v <- lookup("typesandwich"); row_line("Sandwich", v[1], v[2], v[3])},
  {v <- lookup("typewine"); row_line("Wine", v[1], v[2], v[3])},
  "",
  row_line("Perceived image quality"),
  row_line("(ref: Low)"),
  {v <- lookup("quality高质量"); row_line("High", v[1], v[2], v[3])},
  {v <- lookup("quality中质量"); row_line("Medium", v[1], v[2], v[3])},
  "",
  row_line("Attractiveness (ref:"),
  row_line("Neutral)"),
  {v <- lookup("attract无吸引力"); row_line("Unattractive", v[1], v[2], v[3])},
  {v <- lookup("attract有吸引力"); row_line("Attractive", v[1], v[2], v[3])},
  "",
  row_line("Mood (ref: Very negative)"),
  {v <- lookup("mood非常正面"); row_line("Very positive", v[1], v[2], v[3])},
  {v <- lookup("mood负面"); row_line("Negative", v[1], v[2], v[3])},
  {v <- lookup("mood正面"); row_line("Positive", v[1], v[2], v[3])},
  {v <- lookup("mood中立"); row_line("Neutral", v[1], v[2], v[3])},
  "",
  row_line("Memorability score × Food"),
  row_line("type"),
  {v <- lookup("memory_scorelow:typedonut"); row_line("Low × Donut", v[1], v[2], v[3])},
  {v <- lookup("memory_scorelow:typesandwich"); row_line("Low × Sandwich", v[1], v[2], v[3])},
  {v <- lookup("memory_scorelow:typewine"); row_line("Low × Wine", v[1], v[2], v[3])},
  "",
  row_line("Random effects"),
  row_line("Participant (intercept)", paste0("Var = ", fmt_num(var_int$vcov, 2), ","), paste0("SD = ", fmt_num(var_int$sdcor, 2)), ""),
  row_line("Memorability score", paste0("Var = ", fmt_num(var_slope$vcov, 2), ","), paste0("SD = ", fmt_num(var_slope$sdcor, 2)), ""),
  row_line("(slope)"),
  row_line("Residual", paste0("Var = ", fmt_num(var_resid$vcov, 2), ","), paste0("SD = ", fmt_num(var_resid$sdcor, 2)), ""),
  "  --------------------------- ----------- ----------- ---------------------",
  "",
  paste0(
    "*Note. N = ", nrow(model_df), " observations from ", n_distinct(model_df$participant),
    " participants. This sensitivity model removes the 10-50 CNY range filter but keeps the original ",
    "Niming prefilters (marker row and age = -999). Because restored raw records do not contain usable ",
    "trial-order fields, this table controls for perceived image quality, attractiveness, and mood ",
    "but omits image-memory order and food order. ",
    "Significance symbols: † p < .10, * p < .05, ** p < .01, *** p < .001.*"
  )
)

writeLines(table_lines, con = output_table_md)

cat("Wrote:\n")
cat("  ", output_log, "\n", sep = "")
cat("  ", output_table_md, "\n", sep = "")
