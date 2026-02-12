================================================================================
                   FILES FOR:
         "The Economic Value of Image Memorability"
================================================================================

This repository contains the data and code for the empirical
analyses presented in the paper "The Economic Value of Image Memorability."

================================================================================
                           OVERVIEW
================================================================================

This research includes two central questions:
  1. What image features drive memorability? (Study 1)
  2. Does image memorability affect consumer ratings? (Study 2)

================================================================================
                         DATA DESCRIPTION
================================================================================

All data files are located in the "data/input/" directory.

INPUT FILES:
----------------------------------------------------------------------------
| File                    |  Description                        |
|-------------------------|-------------------------------------|
| open_pic_new.xlsx       | Image features for all businesses   |
| restaurant_new.xlsx     | Image features for restaurants      |
| drink_new.xlsx          | Image features for beverage shops   |
| business_feature.csv    | Business-level aggregated metrics   |
----------------------------------------------------------------------------

KEY VARIABLES IN IMAGE DATA:
  - photo_id           : Unique image identifier
  - business_id        : Unique business identifier
  - memory_score       : Image memorability score (0-1, computed via deep
                         learning model; higher values indicate more
                         memorable images)
  - label              : Image content category (food/drink/menu/inside/outside)
  - average_hue        : Average hue value (HSV color space)
  - average_saturation : Average saturation value
  - average_value      : Average brightness value
  - sharpness_measure  : Image clarity metric (Laplacian variance)
  - beauty_score       : Aesthetic quality score (0-10)
  - person_count       : Number of persons detected (YOLO v11)
  - person_exist       : Binary indicator for presence of person (0/1)
  - objects_content    : Detected objects (YOLO v11)

KEY VARIABLES IN BUSINESS DATA:
  - business_id        : Unique business identifier
  - star_avg           : Average consumer rating (outcome variable in Study 2)
  - star_std           : Standard deviation of ratings
  - review_count       : Total number of reviews (proxy for business visibility)
  - contents_score_avg : Average sentiment score of review text
  - categories_counts  : Number of business categories

See "data/input/CODEBOOK.md" for complete variable definitions.

================================================================================
                         CODE DESCRIPTION
================================================================================

MAIN ANALYSIS (Python):
----------------------------------------------------------------------------
| File                    | Description                                     |
|-------------------------|--------------------------------------------------|
| study 1 and 2.ipynb     | Primary analysis notebook containing:            |
|                         |   - Data preprocessing and cleaning              |
|                         |   - Study 1: OLS regression (image features ->   |
|                         |     memorability)                                |
|                         |   - Study 2: IV-2SLS regression (memorability -> |
|                         |     consumer ratings)                            |
|                         |   - Moderation analysis by business visibility   |
|                         |   - Descriptive statistics and summary tables    |
----------------------------------------------------------------------------

IV VALIDITY TESTS (Python):
----------------------------------------------------------------------------
| File                    | Description                                      |
|-------------------------|--------------------------------------------------|
| iv_validity_tests.py    | Class implementing three core IV validity tests: |
|                         |   - Relevance test (first-stage F-statistic)     |
|                         |   - Exclusion restriction (Hansen J test)        |   
| run_iv_tests.py         | Runner script for IV validity diagnostics        |
----------------------------------------------------------------------------

SUPPLEMENTARY ANALYSIS (R):
----------------------------------------------------------------------------
| File                       | Description                                  |
|----------------------------|----------------------------------------------|
| sentiment_score_t_test.RMD | Welch's t-test for sentiment score           |
|                            | differences between high/low visibility      |
|                            | business groups                              |
----------------------------------------------------------------------------

DATA VERIFICATION:
----------------------------------------------------------------------------
| File                    | Description                                     |
|-------------------------|--------------------------------------------------|
| data_statistic.ipynb    | Data quality checks and category verification   |
----------------------------------------------------------------------------

================================================================================
                         SOFTWARE REQUIREMENTS
================================================================================

PYTHON (version 3.7+):
  - pandas >= 1.0.0
  - numpy >= 1.18.0
  - statsmodels >= 0.12.0
  - linearmodels >= 4.25
  - scikit-learn >= 0.24.0
  - scipy >= 1.4.0
  - openpyxl >= 3.0.0

R (version 4.0+):
  - readxl
  - rmarkdown
  - knitr

================================================================================
                       REPLICATION INSTRUCTIONS
================================================================================

STEP 1: Environment Setup
-------------------------
Install required Python packages:
  pip install pandas numpy statsmodels linearmodels scikit-learn scipy openpyxl

Install required R packages:
  install.packages(c("readxl", "rmarkdown", "knitr"))

STEP 2: Run Main Analysis
-------------------------
Open and execute "study 1 and 2.ipynb" in Jupyter Notebook/Lab.
This notebook performs:
  a) Data loading and preprocessing
  b) Study 1: OLS regression analyzing image features -> memorability
  c) Study 2: IV-2SLS regression analyzing memorability -> business ratings
  d) Generates all tables and plot data

STEP 3: Run IV Validity Tests (Optional)
----------------------------------------
Execute from command line:
  python run_iv_tests.py all (restaurant, all business and drink)

Or for specific subsamples:
  python run_iv_tests.py restaurant
  python run_iv_tests.py business (all business)
  python run_iv_tests.py drink

STEP 4: Run Sentiment Analysis (Optional)
-----------------------------------------
run 'sentiment_score_t_test.RMD'

================================================================================
                           OUTPUT FILES 
================================================================================

All output files are generated in the "data/output/" directory:

DESCRIPTIVE STATISTICS:
  - study1_picture_data_summary_yolo11.xlsx : Image-level summary statistics
  - study2_business_data_summary_yolo11.xlsx: Business-level summary statistics
  - bubble_plot_data.xlsx                   : Data for bubble plot visualization

REGRESSION RESULTS:
  - study1_ols.tex                          : Study 1 OLS results (LaTeX format)

PROCESSED DATA (later used in IV test and figure b1, b2):
  - study1_2_business_data.xlsx             : Processed all-business data
  - study1_2_res_data.xlsx                  : Processed restaurant data
  - study1_2_drink_data.xlsx                : Processed beverage shop data

VISUALIZATION DATA:
  - plot_data_moderation_all.csv            : Data for moderation effect plots

SENTIMENT ANALYSIS:
  - all_business_sentiment.xlsx             : Sentiment scores (all businesses)
  - restaurant_sentiment.xlsx               : Sentiment scores (restaurants)
  - drink_sentiment.xlsx                    : Sentiment scores (beverage shops)
  - sentiment_score_t_test.html             : T-test results report


================================================================================
                           CONTACT
================================================================================

For questions regarding the data or code, please contact the corresponding
author at the email address provided in the paper.

================================================================================
                           LICENSE
================================================================================

This code is provided for academic replication purposes only. The underlying
Yelp data is subject to Yelp's terms of service and data use agreement.

================================================================================
