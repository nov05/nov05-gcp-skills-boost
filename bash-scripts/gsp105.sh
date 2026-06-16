


## Task 1
gcloud storage buckets create gs://$BUCKET \
    --default-storage-class=STANDARD \
    --location=$REGION \
    --uniform-bucket-level-access 

## Task 2
gcloud beta services identity create --service=dataprep.googleapis.com