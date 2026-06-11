#!/bin/bash
## Created by nov05, 2026-06-10  
## Refer to GSP081, GSP094, GSP095

ask_to_proceed() {
    echo
    while true; do
        read -rp "Ready to proceed? (y): " answer
        [[ "$answer" =~ ^[Yy]$ ]] && break
    done
    echo
    echo
}

echo
read -p "👉  Enter username 2: " USER_ID2
export USER_ID2
# read -p "👉  Enter bucket name (Task 1): " BUCKET
# export BUCKET 
read -p "👉  Enter topic name (Task 2): " TOPIC
export TOPIC
# read -p "👉  Enter Cloud Run function name (Task 3): " FUNCTION
# export FUNCTION
export FUNCTION="memories-thumbnail-maker"
echo

export USER_ID=$(gcloud auth list --format="value(account)" --filter="status:ACTIVE")
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID \
  --format='value(projectNumber)')
export REGION=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-region])")
export ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export BUCKET="$PROJECT_ID-bucket"
gcloud config set project $PROJECT_ID  
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE
echo
echo "🔹  User ID: $USER_ID"
echo "🔹  User ID 2: $USER_ID2"
echo "🔹  Project ID: $PROJECT_ID"
# echo "🔹  Project number: $PROJECT_NUMBER"
echo "🔹  Region: $REGION"
echo "🔹  Zone: $ZONE"
echo "🔹  Bukect: $BUCKET"
echo "🔹  Topic: $TOPIC"
echo "🔹  Cloud Run function: $FUNCTION"
echo
gcloud auth list

cat << 'EOF'

========================================================
Task 1. Create a bucket
========================================================

EOF

# Create the bucket in the specified region
gsutil mb -l $REGION gs://$BUCKET


cat << 'EOF'

========================================================
Task 2. Create a Pub/Sub topic
========================================================

EOF

gcloud pubsub topics create $TOPIC

cat << 'EOF'

========================================================
Task 3. Create the thumbnail Cloud Run Function
========================================================

EOF
## Refer to GSP081

## ⚠️ The function has to be created via console to pass the lab check.
echo -e "\n👉  Create and deploy Cloud Run funcion $FUNCTION at"  
echo -e "https://console.cloud.google.com/run/services?project=$PROJECT_ID\n"
ask_to_proceed

# echo -e "\n👉  Enabling services..."
# echo -e "Enabling API [eventarc.googleapis.com] will take a few minutes.\n"
# gcloud services enable run.googleapis.com \
#   artifactregistry.googleapis.com \
#   cloudbuild.googleapis.com \
#   eventarc.googleapis.com \
#   --project=$PROJECT_ID
# # until enabled=$(gcloud services list --enabled --project=$PROJECT_ID); \
# #   echo "$enabled" | grep -q run.googleapis.com && \
# #   echo "$enabled" | grep -q artifactregistry.googleapis.com && \
# #   echo "$enabled" | grep -q cloudbuild.googleapis.com
# # do sleep 5; done

# export GCS_SERVICE_AGENT="service-${PROJECT_NUMBER}@gs-project-accounts.iam.gserviceaccount.com"
# echo -e "\n👉  GCS_SERVICE_AGENT: $GCS_SERVICE_AGENT\n"
# gcloud projects add-iam-policy-binding $PROJECT_ID \
#   --member="serviceAccount:$GCS_SERVICE_AGENT" \
#   --role="roles/pubsub.publisher"

# sleep 300

# mkdir myfunc && cd myfunc
# cat > index.js << 'EOF'
# const functions = require('@google-cloud/functions-framework');
# const { Storage } = require('@google-cloud/storage');
# const { PubSub } = require('@google-cloud/pubsub');
# const sharp = require('sharp');

# functions.cloudEvent('memories-thumbnail-maker', async cloudEvent => {
#   const event = cloudEvent.data;

#   console.log(`Event: ${JSON.stringify(event)}`);
#   console.log(`Hello ${event.bucket}`);

#   const fileName = event.name;
#   const bucketName = event.bucket;
#   const size = "64x64";
#   const bucket = new Storage().bucket(bucketName);
#   const topicName = "";
#   const pubsub = new PubSub();

#   if (fileName.search("64x64_thumbnail") === -1) {
#     // doesn't have a thumbnail, get the filename extension
#     const filename_split = fileName.split('.');
#     const filename_ext = filename_split[filename_split.length - 1].toLowerCase();
#     const filename_without_ext = fileName.substring(0, fileName.length - filename_ext.length - 1); // fix sub string to remove the dot

#     if (filename_ext === 'png' || filename_ext === 'jpg' || filename_ext === 'jpeg') {
#       // only support png and jpg at this point
#       console.log(`Processing Original: gs://${bucketName}/${fileName}`);
#       const gcsObject = bucket.file(fileName);
#       const newFilename = `${filename_without_ext}_64x64_thumbnail.${filename_ext}`;
#       const gcsNewObject = bucket.file(newFilename);

#       try {
#         const [buffer] = await gcsObject.download();
#         const resizedBuffer = await sharp(buffer)
#           .resize(64, 64, {
#             fit: 'inside',
#             withoutEnlargement: true,
#           })
#           .toFormat(filename_ext)
#           .toBuffer();

#         await gcsNewObject.save(resizedBuffer, {
#           metadata: {
#             contentType: `image/${filename_ext}`,
#           },
#         });

#         console.log(`Success: ${fileName} → ${newFilename}`);

#         await pubsub
#           .topic(topicName)
#           .publishMessage({ data: Buffer.from(newFilename) });

#         console.log(`Message published to ${topicName}`);
#       } catch (err) {
#         console.error(`Error: ${err}`);
#       }
#     } else {
#       console.log(`gs://${bucketName}/${fileName} is not an image I can handle`);
#     }
#   } else {
#     console.log(`gs://${bucketName}/${fileName} already has a thumbnail`);
#   }
# });
# EOF
# sed -i "s|const topicName = \"\";|const topicName = \"$TOPIC\";|" index.js
# cat > package.json << 'EOF'
# {
#  "name": "thumbnails",
#  "version": "1.0.0",
#  "description": "Create Thumbnail of uploaded image",
#  "scripts": {
#    "start": "node index.js"
#  },
#  "dependencies": {
#    "@google-cloud/functions-framework": "^3.0.0",
#    "@google-cloud/pubsub": "^2.0.0",
#    "@google-cloud/storage": "^6.11.0",
#    "sharp": "^0.32.1"
#  },
#  "devDependencies": {},
#  "engines": {
#    "node": ">=4.3.2"
#  }
# }
# EOF
# cd ..
# echo -e "\n👉  Deploying Cloud Run function 'gcfunction'...\n"
# ## ⚠️ It may need retry a couple of times.
# ## At most one of --trigger-bucket | --trigger-http | --trigger-topic | --trigger-event --trigger-resource | 
# ## --trigger-event-filters --trigger-event-filters-path-pattern --trigger-channel can be specified.
# for i in {1..5}; do
#   gcloud functions deploy gcfunction \
#     --gen2 \
#     --runtime=nodejs22 \
#     --region=$REGION \
#     --source=./myfunc \
#     --entry-point=$FUNCTION \
#     --trigger-bucket=$BUCKET \
#     --allow-unauthenticated \
#     --max-instances=5 \
#     --timeout=300 \
#     --memory=512Mi \
#     --cpu=1 \
#     --concurrency=80 && break
#   sleep 30
# done
# echo -e "\n👉 Deployment done. Check the function at"
# echo -e "https://console.cloud.google.com/run/services?project=$PROJECT_ID\n"

## Tha lab doesn't check whether the function can be triggered.
echo -e "\n👉  Test the Cloud Run function..."
echo -e "Check the bucket at https://console.cloud.google.com/storage/browser/$BUCKET?project=$PROJECT_ID\n"
curl -o map.jpg https://storage.googleapis.com/cloud-training/gsp315/map.jpg
gsutil cp map.jpg gs://$BUCKET/

cat << 'EOF'

========================================================
Task 4. Remove the previous cloud engineer
========================================================

EOF

gcloud projects remove-iam-policy-binding $PROJECT_ID \
  --member="user:$USER_ID2" \
  --role="roles/viewer"


echo -e "\n✅  All done\n"