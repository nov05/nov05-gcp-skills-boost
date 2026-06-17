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
echo
gcloud auth list

export BUCKET="$PROJECT_ID-redact"
export BUCKET2="$PROJECT_ID-input"
export BUCKET3="$PROJECT_ID-output"
export TEMPLATE_NAME=structured_data_template
export TEMPLATE_NAME2=unstructured_data_template

cat << 'EOF'

========================================================
Task 1. Redact sensitive data from text content
========================================================

(No multiple-choice questions found in this task)

EOF
## Refer to GSP107 Task 2, GSP864

gcloud services disable dlp.googleapis.com cloudkms.googleapis.com \
  --project $PROJECT_ID --force
gcloud services enable dlp.googleapis.com cloudkms.googleapis.com \
  --project $PROJECT_ID
until enabled=$(gcloud services list --enabled --project=$PROJECT_ID); \
  echo "$enabled" | grep -q dlp.googleapis.com && \
  echo "$enabled" | grep -q cloudkms.googleapis.com
do sleep 5; done

cat > redact-request.json << EOF
{
	"item": {
		"value": "Please update my records with the following information:\n Email address: foo@example.com,\nNational Provider Identifier: 1245319599"
	},
	"deidentifyConfig": {
		"infoTypeTransformations": {
			"transformations": [{
				"primitiveTransformation": {
					"replaceWithInfoTypeConfig": {}
				}
			}]
		}
	},
	"inspectConfig": {
		"infoTypes": [{
				"name": "EMAIL_ADDRESS"
			},
			{
				"name": "US_HEALTHCARE_NPI"
			}
		]
	}
}
EOF
curl -s \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  https://dlp.googleapis.com/v2/projects/$PROJECT_ID/content:deidentify \
  -d @redact-request.json -o redact-response.txt
cat redact-response.txt
gsutil cp redact-response.txt gs://$BUCKET
gcloud storage ls gs://$BUCKET



cat << 'EOF'

========================================================
Task 2. Create DLP inspection templates
========================================================

(No multiple-choice questions found in this task)

EOF
## Refer to GSP1073 Task 1


curl -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  "https://dlp.googleapis.com/v2/projects/$PROJECT_ID/locations/us/deidentifyTemplates?templateId=$TEMPLATE_NAME" \
  -d '{
    "deidentifyTemplate": {
      "displayName": "",
      "deidentifyConfig": {
        "recordTransformations": {
          "fieldTransformations": [
            {
              "fields": [
                {"name": "bank name"},
                {"name": "zip code"}
              ],
              "primitiveTransformation": {
                "characterMaskConfig": {
                  "maskingCharacter": "#",
                  "numberToMask": 0
                }
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

curl -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  "https://dlp.googleapis.com/v2/projects/$PROJECT_ID/locations/us/deidentifyTemplates?templateId=$TEMPLATE_NAME2" \
  -d '{
    "deidentifyTemplate": {
      "displayName": "",
      "deidentifyConfig": {
        "infoTypeTransformations": {
          "transformations": [
            {
              "primitiveTransformation": {
                "replaceConfig": {
                  "newValue": {
                    "stringValue": "[redacted]"
                  }
                }
              }
            }
          ]
        }
      }
    }
  }'
sleep 10
echo -e "\n👉  Check the templates at"
echo -e "https://console.cloud.google.com/security/sensitive-data-protection/landing/configuration/templates/deidentify?project=$PROJECT_ID\n"



cat << 'EOF'

========================================================
Task 3. Configure a job trigger to run DLP inspection
========================================================

(No multiple-choice questions found in this task)

EOF
## Refert to GSP1073 Task 2 and 3
## https://docs.cloud.google.com/sdk/gcloud/reference/alpha/dlp/jobs

curl -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  "https://dlp.googleapis.com/v2/projects/$PROJECT_ID/locations/us/jobTriggers?triggerId=dlp_job" \
  -d '{
    "jobTrigger": {
      "displayName": "dlp_job",
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
                "bucketName": "'"${BUCKET2}"'",
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
              "cloudStorageOutput": "gs://'"${BUCKET3}"'",
              "transformationConfig": {
                "deidentifyTemplate": "projects/'"$PROJECT_ID"'/locations/us/deidentifyTemplates/unstructured_data_template",
                "structuredDeidentifyTemplate": "projects/'"$PROJECT_ID"'/locations/us/deidentifyTemplates/structured_data_template"
              }
            }
          }
        ]
      }
    }
  }'

sleep 30
gcloud alpha dlp job-triggers list \
  --filter="name:dlp_job"
echo -e "\n👉  Check the trigger 'dlp_job' at"
echo -e "https://console.cloud.google.com/security/sensitive-data-protection/landing/inspection/triggers?project=$PROJECT_ID\n"

curl -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  "https://dlp.googleapis.com/v2/projects/$PROJECT_ID/locations/us/jobTriggers/dlp_job:activate"
sleep 30
echo -e "\n👉  Check the jobs for 'dlp_job' at"
echo -e "https://console.cloud.google.com/security/sensitive-data-protection/landing/inspection/jobs?project=$PROJECT_ID\n"
JOB_ID=$(gcloud alpha dlp jobs list \
  --location=us \
  --format="value(name)" \
  --limit=1)
echo "\n👉  Job ID: $JOB_ID\n"
## https://docs.cloud.google.com/sdk/gcloud/reference/alpha/dlp/jobs/describe
## It does NOT support --location. And it won't find the job without location.
# gcloud alpha dlp jobs describe $JOB_ID
curl -X GET \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  "https://dlp.googleapis.com/v2/projects/$PROJECT_ID/locations/us/dlpJobs/$JOB_ID" \
  | jq . | head -n 10

: << 'E.g.
{
  "name": "projects/qwiklabs-gcp-01-78b8a1917307/locations/us/dlpJobs/i-3619213168265786675",
  "type": "INSPECT_JOB",
  "state": "DONE",
  "inspectDetails": {
    "requestedOptions": {
      "snapshotInspectTemplate": {},
      "jobConfig": {
        "storageConfig": {
          "cloudStorageOptions": {
'

gcloud storage ls gs://$BUCKET3
gcloud storage ls --recursive gs://$BUCKET3/**






echo -e "\n✅  All done\n"