# Data Dictionary

This directory contains input data for Study 1 & 2: analyzing how image features affect memorability and how image memorability influences business ratings.

## Overview

| File                     | Description                                       |
| ------------------------ | ------------------------------------------------- |
| `open_pic_new.xlsx`    | Complete image feature dataset for all businesses |
| `restaurant_new.xlsx`  | Subset: restaurant images only                    |
| `drink_new.xlsx`       | Subset: beverage shop images only                 |
| `business_feature.csv` | Yelp business data    |

---

## 1. open_pic_new.xlsx

Complete image feature dataset for all businesses.

| #  | Field Name              | Type   | Description                                             |
| -- | ----------------------- | ------ | ------------------------------------------------------- |
| 1  | `photo_id`            | string | Unique image identifier                                 |
| 2  | `business_id`         | string | Unique business identifier                              |
| 3  | `caption`             | string | Image caption/description text                          |
| 4  | `label`               | string | Image category label (food/drink/menu/inside/outside)   |
| 5  | `memory_score`        | float  | Image memorability score (0-1, higher = more memorable) |
| 6  | `pic_filename`        | string | Image filename                                          |
| 7  | `average_hue`         | float  | Average hue value (0-360)                               |
| 8  | `average_saturation`  | float  | Average saturation value (0-1)                          |
| 9  | `average_value`       | float  | Average brightness value (0-1)                          |
| 10 | `number_face`         | int    | Number of faces detected                                |
| 11 | `smiling_faces_count` | int    | Number of smiling faces detected                        |
| 12 | `sharpness_measure`   | float  | Image sharpness/clarity metric (Laplacian variance)     |
| 13 | `detected_text`       | string | Text detected in image (OCR)                            |
| 14 | `uniqueness_score`    | float  | Image uniqueness score (0-1)                            |
| 15 | `person_count`        | int    | Number of persons detected in image (YOLO)              |
| 16 | `person_exist`        | int    | Binary: whether person exists (0/1)                     |
| 17 | `objects_content`     | string | Comma-separated list of detected objects (YOLO v11)     |
| 18 | `name`                | string | Business name                                           |
| 19 | `address`             | string | Street address                                          |
| 20 | `city`                | string | City                                                    |
| 21 | `state`               | string | State/Province                                          |
| 22 | `postal_code`         | string | Postal/ZIP code                                         |
| 23 | `latitude`            | float  | Geographic latitude                                     |
| 24 | `longitude`           | float  | Geographic longitude                                    |
| 25 | `stars`               | float  | Business star rating (1-5)                              |
| 26 | `review_count`        | int    | Total number of reviews                                 |
| 27 | `is_open`             | int    | Whether business is currently open (0/1)                |
| 28 | `attributes`          | string | Business attributes (JSON)                              |
| 29 | `categories`          | string | Business categories (comma-separated)                   |
| 30 | `hours`               | string | Operating hours (JSON)                                  |
| 31 | `beauty_score`        | float  | Aesthetic quality score (0-10)                          |

---

## 2. restaurant_new.xlsx

Subset containing restaurant images only. Same structure as `open_pic_new.xlsx`.

---

## 3. drink_new.xlsx

Subset containing beverage shop images only. Same structure as `open_pic_new.xlsx`, with additional fields:

| #  | Field Name   | Type   | Description                 |
| -- | ------------ | ------ | --------------------------- |
| 32 | `cate_new` | string | New category classification |
| 33 | `mark`     | string | Beverage category marker    |

---

## 4. business_feature.csv

Aggregated business-level metrics derived from Yelp review data.

| #  | Field Name             | Type   | Description                                       |
| -- | ---------------------- | ------ | ------------------------------------------------- |
| 1  | `business_id`        | string | Unique business identifier                        |
| 2  | `stars`              | float  | Business star rating (1-5)                        |
| 3  | `review_count`       | int    | Total number of reviews                           |
| 4  | `is_open`            | int    | Whether business is open (0/1)                    |
| 5  | `categories_counts`  | int    | Number of categories the business belongs to      |
| 6  | `user_count`         | int    | Number of unique reviewers                        |
| 7  | `star_avg`           | float  | Average user rating (outcome variable in Study 2) |
| 8  | `star_std`           | float  | Standard deviation of user ratings                |
| 9  | `contents_score_avg` | float  | Average sentiment score of review content         |
| 10 | `useful_avg`         | float  | Average "useful" votes per review                 |
| 11 | `funny_avg`          | float  | Average "funny" votes per review                  |
| 12 | `cool_avg`           | float  | Average "cool" votes per review                   |

---
