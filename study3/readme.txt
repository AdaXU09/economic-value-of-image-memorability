================================================================================              
        "The Economic Value of Image Memorability" STUDY 3
================================================================================

DIRECTORY STRUCTURE
--------------------------------------------------------------------------------
study3/
|
|-- readme.txt                  # This file
|-- study3.ipynb                # Python analysis (data processing, OLS, t-tests)
|-- model.Rmd                   # R analysis (mixed-effects models, ANOVA)
|-- sensitivity_no_10_50_c5.R   # R analysis (appendix table C5, sensitivity check)
|
|-- data/
|   |-- input/
|   |   |-- CODEBOOK.md           # Detailed data dictionary
|   |   |-- naodao.csv          # Raw survey data (with participant IDs)
|   |   |-- niming.csv          # Raw survey data (anonymous version)
|   |   |-- memory_score.xlsx   # Reference memorability scores for 8 images
|   |   |-- final_data_order_all.csv  # Processed data for modeling
|   |
|   |-- output/
|       |-- model.html          # R Markdown output (mixed-effects analysis)
|       |-- study3.tex          # LaTeX regression table


SOFTWARE REQUIREMENTS
--------------------------------------------------------------------------------
Python (>=3.8):
  - pandas
  - numpy
  - statsmodels
  - scipy

R (>=4.0):
  - lme4
  - lmerTest
  - emmeans
  - multcomp
  - quantreg
  - rmarkdown

INSTRUCTIONS
--------------------------------------------------------------------------------
1. DATA PREPROCESSING AND OLS ANALYSIS (Python):

   Open study3.ipynb in Jupyter Notebook/Lab and run all cells sequentially.

   This script performs:
   - Data loading and cleaning (filtering valid responses: 10<=score<=50)
   - Spearman correlation between memory scores and corrected recognition (CR)
   - Paired t-tests comparing high vs. low memorability images
   - OLS regression for each food category
   - LaTeX table generation (output: data/output/study3.tex)

2. MIXED-EFFECTS MODEL ANALYSIS (R):

   Open model.Rmd in RStudio and knit to HTML.

   This script performs:
   - Linear mixed-effects model with random intercepts and slopes
   - Type III ANOVA
   - Post-hoc analysis with estimated marginal means
   - Quantile regression (median, tau=0.5)
   - Output: data/output/model.html


VARIABLE CODING (Chinese to English)
--------------------------------------------------------------------------------
Mood (mood):
  - 非常正面 = Very Positive
  - 正面 = Positive
  - 中立 = Neutral
  - 负面 = Negative
  - 非常负面 = Very Negative

Quality (quality):
  - 高质量 = High Quality
  - 中质量 = Medium Quality
  - 低质量 = Low Quality

Attractiveness (attract):
  - 有吸引力 = Attractive
  - 无吸引力 = Unattractive
  - 无区别 = No Difference

ETHICAL CONSIDERATIONS
--------------------------------------------------------------------------------
- All participant data has been anonymized
- Participant identifiers (UserId, Subject Name) have been de-identified from data. 
- IP addresses have been masked in all files

CONTACT
--------------------------------------------------------------------------------
For questions regarding these replication materials, please contact the
corresponding author of the paper.

================================================================================
                              END OF README
================================================================================
