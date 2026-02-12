# Data Dictionary

This directory contains input data for Study 3: examining the causal effect of image memorability on participant ratings using experimental survey data.

## Overview

| File                         | Description                                                                     |
| ---------------------------- | ------------------------------------------------------------------------------- |
| `naodao.csv`               | Survey responses with participant identifiers                                   |
| `niming.csv`               | Anonymous version of survey responses (no UserId/Name)                          |
| `memory_score.xlsx`        | Reference memorability scores for 8 experimental images                         |
| `final_data_order_all.csv` | Participant ratings for each experimental image along with associated metadata. |

---

## 1. memory_score.xlsx

Reference table containing memorability scores for the 8 images used in the experiment (2 images per category × 4 categories: Wine, Cake, Sandwich, Donut).

| # | Field Name       | Type   | Description                    |
| - | ---------------- | ------ | ------------------------------ |
| 1 | `pic_name`     | string | Image name/identifier          |
| 2 | `memory_score` | float  | Image memorability score (0-1) |
| 3 | `pic`          | string | Image file path or reference   |

---

## 2. naodao.csv

Survey responses with participant identifiers. Total 67 columns.

| Field Name         | Type     | Description                                               |
| ------------------ | -------- | --------------------------------------------------------- |
| `Num`            | int      | Sequence number                                           |
| `UserId`         | string   | User ID                                                   |
| `Subject IDs`    | string   | Participant record ID                                     |
| `Subject Name`   | string   | Participant nickname                                      |
| `Time`           | datetime | Submission time                                           |
| `Duration`       | int      | Time spent (seconds)                                      |
| `Source`         | string   | Source                                                    |
| `Source Details` | string   | Source details                                            |
| `IP`             | string   | IP address                                                |
| `NodeId`         | string   | Node ID                                                   |
| `Node`           | string   | Node name                                                 |
| `Info_Q1`        | string   | What is your age?                                         |
| `Info_Q2`        | string   | What is your gender?                                      |
| `Info_Q3`        | string   | What is your highest education level?                     |
| `Info_Q4`        | string   | What is your current occupation?                          |
| `Info_Q5`        | string   | What is your household annual income?                     |
| `Info_Q6`        | string   | What is your marital status?                              |
| `Info_Q7`        | string   | How many children do you have?                            |
| `NodeId.1`       | string   | Node ID (section 1)                                       |
| `Node.1`         | string   | Node name (section 1)                                     |
| `Que_Q2`         | int      | How is your mood during this experiment?                  |
| `Que_Q3`         | int      | How do you rate the photo quality of this image?          |
| `Que_Q4`         | int      | How do you rate the photo quality of this image?          |
| `Que_Q5`         | int      | How do you rate the photo quality of this image?          |
| `Que_Q6`         | int      | How do you rate the photo quality of this image?          |
| `Que_Q7`         | int      | How do you rate the photo quality of this image?          |
| `Que_Q8`         | int      | How do you rate the photo quality of this image?          |
| `Que_Q9`         | int      | How do you rate the photo quality of this image?          |
| `Que_Q10`        | int      | How do you rate the photo quality of this image?          |
| `Que_Q11`        | int      | Attractiveness 1                                          |
| `Que_Q12`        | int      | Attractiveness 2                                          |
| `Que_Q13`        | int      | Attractiveness 3                                          |
| `Que_Q14`        | int      | Attractiveness 4                                          |
| `NodeId.2`       | string   | Node ID (section 2)                                       |
| `Node.2`         | string   | Node name (section 2)                                     |
| `Que_Q2.1`       | int      | Have you seen this picture before?                        |
| `Que_Q3.1`       | int      | Have you seen this picture before?                        |
| `Que_Q4.1`       | int      | Have you seen this picture before?                        |
| `Que_Q5.1`       | int      | Have you seen this picture before?                        |
| `Que_Q6.1`       | int      | Have you seen this picture before?                        |
| `Que_Q7.1`       | int      | Have you seen this picture before?                        |
| `Que_Q8.1`       | int      | Have you seen this picture before?                        |
| `Que_Q9.1`       | int      | Have you seen this picture before?                        |
| `Que_Q10.1`      | int      | Have you seen this picture before?                        |
| `Que_Q11.1`      | int      | Have you seen this picture before?                        |
| `Que_Q12.1`      | int      | Have you seen this picture before?                        |
| `Que_Q13.1`      | int      | Have you seen this picture before?                        |
| `Que_Q14.1`      | int      | Have you seen this picture before?                        |
| `Que_Q15`        | int      | Have you seen this picture before?                        |
| `Que_Q16`        | int      | Have you seen this picture before?                        |
| `Que_Q17`        | int      | Have you seen this picture before?                        |
| `NodeId.3`       | string   | Node ID (section 3)                                       |
| `Node.3`         | string   | Node name (section 3)                                     |
| `Que_Q2_1`       | int      | Max willingness to pay for a cake (without image; warm up question) (10-50 yuan): Price     |
| `Que_Q3_1`       | int      | Max willingness to pay for a donut (without image; warm up question) (10-50 yuan): Price    |
| `Que_Q4_1`       | int      | Max willingness to pay for a sandwich (without image; warm up question) (10-50 yuan): Price |
| `Que_Q5_1`       | int      | Max willingness to pay for a beer (without image;warm up question) (10-50 yuan): Price     |
| `NodeId.4`       | string   | Node ID (section 4)                                       |
| `Node.4`         | string   | Node name (section 4)                                     |
| `Que_Q2_item1`   | int      | Pair 1 Image 1 Max willingness to pay (value between 10-50)                      |
| `Que_Q2_item2`   | int      | Pair 1 Image 2 Max willingness to pay (value between 10-50)                      |
| `Que_Q3_item1`   | int      | Pair 2 Image 1 Max willingness to pay (value between 10-50)                      |
| `Que_Q3_item2`   | int      | Pair 2 Image 2 Max willingness to pay (value between 10-50)                      |
| `Que_Q4_item1`   | int      | Pair 3 Image 1 Max willingness to pay (value between 10-50)                      |
| `Que_Q4_item2`   | int      | Pair 3 Image 2 Max willingness to pay (value between 10-50)                      |
| `Que_Q5_item1`   | int      | Pair 4 Image 1 Max willingness to pay (value between 10-50)                      |
| `Que_Q5_item2`   | int      | Pair 4 Image 2 Max willingness to pay (value between 10-50)                      |

---

## 3. niming.csv

Anonymous version of survey responses. Total 65 columns (same as `naodao.csv` without `UserId` and `Subject Name`).

| Field Name         | Type     | Description                                               |
| ------------------ | -------- | --------------------------------------------------------- |
| `Num`            | int      | Sequence number                                           |
| `Subject IDs`    | string   | Participant record ID                                     |
| `Time`           | datetime | Submission time                                           |
| `Duration`       | int      | Time spent (seconds)                                      |
| `Source`         | string   | Source                                                    |
| `Source Details` | string   | Source details                                            |
| `IP`             | string   | IP address                                                |
| `NodeId`         | string   | Node ID                                                   |
| `Node`           | string   | Node name                                                 |
| `Info_Q1`        | string   | What is your age?                                         |
| `Info_Q2`        | string   | What is your gender?                                      |
| `Info_Q3`        | string   | What is your highest education level?                     |
| `Info_Q4`        | string   | What is your current occupation?                          |
| `Info_Q5`        | string   | What is your household annual income?                     |
| `Info_Q6`        | string   | What is your marital status?                              |
| `Info_Q7`        | string   | How many children do you have?                            |
| `NodeId.1`       | string   | Node ID (section 1)                                       |
| `Node.1`         | string   | Node name (section 1)                                     |
| `Que_Q2`         | int      | How is your mood during this experiment?                  |
| `Que_Q3`         | int      | How do you rate the photo quality of this image?          |
| `Que_Q4`         | int      | How do you rate the photo quality of this image?          |
| `Que_Q5`         | int      | How do you rate the photo quality of this image?          |
| `Que_Q6`         | int      | How do you rate the photo quality of this image?          |
| `Que_Q7`         | int      | How do you rate the photo quality of this image?          |
| `Que_Q8`         | int      | How do you rate the photo quality of this image?          |
| `Que_Q9`         | int      | How do you rate the photo quality of this image?          |
| `Que_Q10`        | int      | How do you rate the photo quality of this image?          |
| `Que_Q11`        | int      | Attractiveness 1                                          |
| `Que_Q12`        | int      | Attractiveness 2                                          |
| `Que_Q13`        | int      | Attractiveness 3                                          |
| `Que_Q14`        | int      | Attractiveness 4                                          |
| `NodeId.2`       | string   | Node ID (section 2)                                       |
| `Node.2`         | string   | Node name (section 2)                                     |
| `Que_Q2.1`       | int      | Have you seen this picture before?                        |
| `Que_Q3.1`       | int      | Have you seen this picture before?                        |
| `Que_Q4.1`       | int      | Have you seen this picture before?                        |
| `Que_Q5.1`       | int      | Have you seen this picture before?                        |
| `Que_Q6.1`       | int      | Have you seen this picture before?                        |
| `Que_Q7.1`       | int      | Have you seen this picture before?                        |
| `Que_Q8.1`       | int      | Have you seen this picture before?                        |
| `Que_Q9.1`       | int      | Have you seen this picture before?                        |
| `Que_Q10.1`      | int      | Have you seen this picture before?                        |
| `Que_Q11.1`      | int      | Have you seen this picture before?                        |
| `Que_Q12.1`      | int      | Have you seen this picture before?                        |
| `Que_Q13.1`      | int      | Have you seen this picture before?                        |
| `Que_Q14.1`      | int      | Have you seen this picture before?                        |
| `Que_Q15`        | int      | Have you seen this picture before?                        |
| `Que_Q16`        | int      | Have you seen this picture before?                        |
| `Que_Q17`        | int      | Have you seen this picture before?                        |
| `NodeId.3`       | string   | Node ID (section 3)                                       |
| `Node.3`         | string   | Node name (section 3)                                     |
| `Que_Q2_1`       | int      | Max willingness to pay for a cake (without image; warm up question) (10-50 yuan): Price     |
| `Que_Q3_1`       | int      | Max willingness to pay for a donut (without image; warm up question) (10-50 yuan): Price    |
| `Que_Q4_1`       | int      | Max willingness to pay for a sandwich (without image; warm up question) (10-50 yuan): Price |
| `Que_Q5_1`       | int      | Max willingness to pay for a beer (without image;warm up question) (10-50 yuan): Price      |
| `NodeId.4`       | string   | Node ID (section 4)                                       |
| `Node.4`         | string   | Node name (section 4)                                     |
| `Que_Q2_item1`   | int      | Pair 1 Image 1 Max willingness to pay (value between 10-50)                      |
| `Que_Q2_item2`   | int      | Pair 1 Image 2 Max willingness to pay (value between 10-50)                      |
| `Que_Q3_item1`   | int      | Pair 2 Image 1 Max willingness to pay (value between 10-50)                      |
| `Que_Q3_item2`   | int      | Pair 2 Image 2 Max willingness to pay (value between 10-50)                      |
| `Que_Q4_item1`   | int      | Pair 3 Image 1 Max willingness to pay (value between 10-50)                      |
| `Que_Q4_item2`   | int      | Pair 3 Image 2 Max willingness to pay (value between 10-50)                      |
| `Que_Q5_item1`   | int      | Pair 4 Image 1 Max willingness to pay (value between 10-50)                      |
| `Que_Q5_item2`   | int      | Pair 4 Image 2 Max willingness to pay (value between 10-50)                      |

---

## 4. final_data_order_all.csv

Participant ratings for each experimental image along with associated metadata.

| #  | Field Name             | Type   | Description                                     |
| -- | ---------------------- | ------ | ----------------------------------------------- |
| 1  | `participant`        | int    | Participant ID                                  |
| 2  | `type`               | string | Food category (wine/cake/sandwich/donut)        |
| 3  | `score`              | int    | Participant's maximum willingness to pay (10-50)              |
| 4  | `memory_score`       | string | Memorability level (high/low)                   |
| 5  | `image_memory_order` | int    | The presentation order of the image pairs (1/2/3/4)           |
| 6  | `food_order`         | int    | The left-right presentation order of the images (1/2) |
| 7  | `quality`            | string | Perceived image quality               |
| 8  | `attract`            | string | Perceived attractiveness              |
| 9  | `mood`               | string | Mood             |
| 10 | `image_id`           | int    | Image identifier (1-8)                               |

---
