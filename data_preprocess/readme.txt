===================================================================================
                        DATA PREPROCESSING PIPELINE
===================================================================================

PREREQUISITE: Download raw data from Yelp Open Dataset
  https://business.yelp.com/data/resources/open-dataset/

===================================================================================
1. raw_business_data_process.ipynb
===================================================================================
   Description: Converts raw Yelp JSON files to Excel/CSV, calculates review
                sentiment scores, extracts memory scores from photos, and
                generates business-level aggregated features.

   Input:
     - data/json/*.json (raw Yelp JSON files: business, review, tip, photo)
     - data/pic/*.jpg (raw Yelp photos for memory score calculation)

   Output:
     - data/excel/yelp_academic_dataset_business.xlsx (business data: convert from JSON) 
     - data/excel/yelp_academic_dataset_review.csv (review data: convert from JSON)
     - data/excel/review_result.csv (review aggregated by business_id)
     - data/excel/business_result.xlsx (business features)
     - data/excel/business_feature.csv (merged business + review data)
     - data/excel/photos_result.xlsx (photo metadata with memory_score, h, s, v) 

===================================================================================
2. raw_picture_data_process.ipynb (in "image feature extraction" folder)
===================================================================================
   Description: Extracts image features (HSV, face detection, smiling faces,
                clarity, color uniqueness, object detection via YOLO11) and
                merges with business data to create picture-level dataset.

   Dependencies:
     - improved-aesthetic-predictor-main (download from GitHub:
       https://github.com/christophschuhmann/improved-aesthetic-predictor)
       Used for calculating aesthetic scores of images.

   Input:
     - data/pic/*.jpg (raw Yelp photos)
     - data/excel/yelp_academic_dataset_business.xlsx (from step 1)
     - data/excel/photos_result.xlsx (from step 1)
     - data/pic/generate_result.xlsx (extracted features(intermediate results): HSV, face, clarity, etc.)
     - data/pic/result_object_detect_yolo11.txt (YOLO11 object detection results (intermediate results))

   Output:
     - data/pic/pic_feature.xlsx (final picture features merged with business data)
       Columns: photo_id, business_id, caption, label, memory_score, pic_filename, average_hue,
                average_saturation, average_value, number_face, smiling_faces_count,
                sharpness_measure, detected_text, uniqueness_score, person_count,
                person_exist, objects_content, name, address, city, state,
                postal_code, latitude, longitude, stars, review_count, is_open,
                attributes, categories, hours

===================================================================================
3. pic_all_res_drink_data_process.ipynb
===================================================================================
   Description: Filters open businesses and divides data into subsamples
                (restaurant and drink) for analysis.

   Input:
     - data/input/pic_feature.xlsx (from step 2)

   Output:
     - data/output/open_pic_new.xlsx (open businesses only)
     - data/output/restaurant_new.xlsx (restaurant subsample)
     - data/output/drink_new.xlsx (drink-related subsample: bar, coffee, tea, cafe, pub)

All the output will be used in study 1 and study 2 analysis.
