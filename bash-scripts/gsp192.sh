cat << 'EOF'

========================================================
Task 1. Ensure that the Dataflow API is successfully re-enabled
========================================================

EOF

gcloud services disable dataflow.googleapis.com --project $PROJECT_ID --force
gcloud services enable dataflow.googleapis.com --project $PROJECT_ID


cat << 'EOF'

========================================================
Task 2. Create a BigQuery dataset, BigQuery table, and Cloud Storage bucket using Cloud Shell
========================================================

EOF

bq mk taxirides
bq mk \
    --time_partitioning_field timestamp \
    --schema \
ride_id:string,point_idx:integer,latitude:float,longitude:float,\
timestamp:timestamp,meter_reading:float,meter_increment:float,ride_status:string,\
passenger_count:integer \
    -t taxirides.realtime

export BUCKET_NAME=""
gsutil mb gs://$BUCKET_NAME/


cat << 'EOF'

========================================================
Task 3. Create a BigQuery dataset, BigQuery table, and Cloud Storage bucket using the Google Cloud console
========================================================

Question 1: Which service is used to create the dataset in this task?
Answer: BigQuery

Question 2: What dataset name is used in the lab?
Answer: taxirides

EOF


cat << 'EOF'

========================================================
Task 4. Run the pipeline
========================================================

EOF

gcloud dataflow jobs run iotflow \
    --gcs-location gs://dataflow-templates-"Region"/latest/PubSub_to_BigQuery \
    --region "$REGION" \
    --worker-machine-type e2-medium \
    --staging-location gs://"$BUCKET_NAME"/temp \
    --parameters inputTopic=projects/pubsub-public-data/topics/taxirides-realtime,outputTableSpec="Table Name":taxirides.realtime


cat << 'EOF'

========================================================
Task 5. Submit a query
========================================================

In the BigQuery Editor, add the following to query the data in your project.
SELECT * FROM `"Bucket Name".taxirides.realtime` LIMIT 1000

EOF


cat << 'EOF'

========================================================
Task 6. Test your understanding
========================================================

Question 1: Google Cloud Dataflow supports batch processing.
Answer: True

Question 2: Which Dataflow Template used in the lab to run the pipeline?
Answer: Pub/Sub to BigQuery

EOF

echo -e "\n✅  All done\n"