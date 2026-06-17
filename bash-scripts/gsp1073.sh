#!/bin/bash
## Created by nov05, 2026-06-16

export USER_ID=$(gcloud auth list --format="value(account)" --filter="status:ACTIVE")
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID \
  --format='value(projectNumber)')
export REGION=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-region])")
export ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export BUCKET="$PROJECT_ID-input"
export BUCKET2="$PROJECT_ID-output"
gcloud config set account $USER_ID
gcloud config set project $PROJECT_ID  
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE
echo
echo "🔹  User: $USER"
echo "🔹  Username: $USER_ID"
echo "🔹  Project ID: $PROJECT_ID"
echo "🔹  Project number: $PROJECT_NUMBER"
echo "🔹  Region: $REGION"
echo "🔹  Zone: $ZONE"
echo "🔹  Bukect (input): $BUCKET"
echo "🔹  Bukect (output): $BUCKET2"
echo
gcloud auth list


cat << 'EOF'

========================================================
Task 1. Create de-identify templates
========================================================

(No multiple-choice questions found in this task)

EOF

gcloud services disable dlp.googleapis.com cloudkms.googleapis.com \
  --project $PROJECT_ID --force
gcloud services enable dlp.googleapis.com cloudkms.googleapis.com \
  --project $PROJECT_ID
until enabled=$(gcloud services list --enabled --project=$PROJECT_ID); \
  echo "$enabled" | grep -q dlp.googleapis.com && \
  echo "$enabled" | grep -q cloudkms.googleapis.com
do sleep 5; done

curl -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  "https://dlp.googleapis.com/v2/projects/$PROJECT_ID/deidentifyTemplates?templateId=deid_unstruct1" \
  -d '{
    "deidentifyTemplate": {
      "displayName": "deid_unstruct1 template",
      "deidentifyConfig": {
        "infoTypeTransformations": {
          "transformations": [
            {
              "primitiveTransformation": {
                "replaceWithInfoTypeConfig": {}
              }
            }
          ]
        }
      }
    }
  }'

curl -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  "https://dlp.googleapis.com/v2/projects/$PROJECT_ID/deidentifyTemplates?templateId=deid_struct1" \
  -d '{
    "deidentifyTemplate": {
      "displayName": "deid_struct1 template",
      "deidentifyConfig": {
        "recordTransformations": {
          "fieldTransformations": [
            {
              "fields": [
                {"name": "ssn"},
                {"name": "ccn"},
                {"name": "email"},
                {"name": "vin"},
                {"name": "id"},
                {"name": "agent_id"},
                {"name": "user_id"}
              ],
              "primitiveTransformation": {
                "replaceConfig": {}
              }
            },
            {
              "fields": [
                {"name": "message"}
              ],
              "infoTypeTransformations": {
                "transformations": [
                  {
                    "primitiveTransformation": {
                      "replaceWithInfoTypeConfig": {}
                    }
                  }
                ]
              }
            }
          ]
        }
      }
    }
  }'

echo -e "\n👉  Check the templates at"
echo -e "https://console.cloud.google.com/security/sensitive-data-protection/landing/configuration/templates/deidentify?project=$PROJECT_ID\n"


cat << 'EOF'

========================================================
Task 2. Create a DLP inspection job trigger
========================================================

(No multiple-choice questions found in this task)

EOF
## https://docs.cloud.google.com/sdk/gcloud/reference/alpha/dlp/job-triggers/create

curl -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  "https://dlp.googleapis.com/v2/projects/$PROJECT_ID/locations/global/jobTriggers?triggerId=DeID_Storage_Demo1" \
  -d '{
    "jobTrigger": {
      "displayName": "DeID_Storage_Demo1",
      "triggers": [
        {
          "schedule": {
            "recurrencePeriodDuration": {
              "seconds": 604800
            }
          }
        }
      ],
      "inspectJob": {
        "inspectConfig": {
          "infoTypes": []
        },
        "storageConfig": {
          "cloudStorageOptions": {
            "fileSet": {
              "regexFileSet": {
                "bucketName": "'"${BUCKET}"'",
                "includeRegex": [".*"],
                "excludeRegex": []
              }
            },
            "filesLimitPercent": 100
          }
        },
        "actions": [
          {
            "deidentify": {
              "cloudStorageOutput": "gs://'"${BUCKET2}"'",
              "transformationConfig": {
                "deidentifyTemplate": "projects/'"$PROJECT_ID"'/locations/global/deidentifyTemplates/deid_unstruct1",
                "structuredDeidentifyTemplate": "projects/'"$PROJECT_ID"'/locations/global/deidentifyTemplates/deid_struct1"
              }
            }
          }
        ]
      }
    }
  }'

gcloud alpha dlp job-triggers list \
  --filter="name:DeID_Storage_Demo1"
echo -e "\n👉  Check the trigger 'DeID_Storage_Demo1' at"
echo -e "https://console.cloud.google.com/security/sensitive-data-protection/landing/inspection/triggers?project=$PROJECT_ID\n"


cat << 'EOF'

========================================================
Task 3. Run DLP Inspection and review results
========================================================

(No multiple-choice questions found in this task)

EOF
## https://docs.cloud.google.com/sdk/gcloud/reference/alpha/dlp/jobs



curl -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  "https://dlp.googleapis.com/v2/projects/$PROJECT_ID/locations/global/jobTriggers/DeID_Storage_Demo1:activate"
echo -e "\n👉  Check the jobs for 'DeID_Storage_Demo1' at"
echo -e "https://console.cloud.google.com/security/sensitive-data-protection/landing/inspection/jobs?project=$PROJECT_ID\n"

JOB_ID=$(gcloud alpha dlp jobs list \
  --format="value(name)" \
  --limit=1)
gcloud alpha dlp jobs describe $JOB_ID

# gsutil ls gs://$BUCKET
# gsutil ls -r gs://$BUCKET/**
gcloud storage ls gs://$BUCKET
gcloud storage ls --recursive gs://$BUCKET/**


echo -e "\n✅  All done\n"