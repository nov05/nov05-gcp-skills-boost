#!/bin/bash
## Created by nov05, 2026-06-09 

set -e

echo
read -p "👉  Enter VM instance name: " VM_NAME
export VM_NAME
read -p "👉  Enter Task 2 result file name: " TASK2_RESULT
export TASK2_RESULT
read -p "👉  Enter Task 3 request file name: " TASK3_REQUEST
export TASK3_REQUEST
read -p "👉  Enter Task 3 result file name: " TASK3_RESULT
export TASK3_RESULT
read -p "👉  Enter Task 4 text: " TASK4_TEXT
export TASK4_TEXT
read -p "👉  Enter Task 4 result file name: " TASK4_RESULT
export TASK4_RESULT
read -p "👉  Enter Task 5 text: " TASK5_TEXT
export TASK5_TEXT
read -p "👉  Enter Task 5 result file name: " TASK5_RESULT
export TASK5_RESULT
echo

## Get project id, project number, region, zone
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID \
  --format='value(projectNumber)')
export REGION=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-region])")
export ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
# export USER_EMAIL=$(gcloud auth list --format="value(account)" --filter="status:ACTIVE")
# export BUCKET="$PROJECT_ID-bucket"
# gcloud config set project $(gcloud projects list --format='value(PROJECT_ID)' --filter='qwiklabs-gcp')
gcloud config set project $PROJECT_ID  
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE
echo
echo "🔹  User: $USER"
# echo "🔹  User email: $USER_EMAIL"
echo "🔹  Project ID: $PROJECT_ID"
# echo "🔹  Project number: $PROJECT_NUMBER"
echo "🔹  Region: $REGION"
echo "🔹  Zone: $ZONE"
# echo "🔹  Bukect: $BUCKET"
echo
gcloud auth list

cat << 'EOF'

========================================================
Task 1. Create an API key
========================================================

EOF
## Create an API key to use in this and other tasks when sending a request to the Speech-to-Text API.
## Refer to GSP048

gcloud services enable apikeys.googleapis.com
until gcloud services list --enabled \
  --project=$PROJECT_ID | grep -q apikeys.googleapis.com
do sleep 5; done

## Delete multiple API keys by the display name
## -r (--no-run-if-empty)
export API_DISPLAY_NAME=arc132-api-key
gcloud alpha services api-keys list \
    --filter="displayName:$API_DISPLAY_NAME" \
    --format="value(name)" \
| xargs -r -n 1 gcloud alpha services api-keys delete \
    --location=global

## Create API key and limit the services
gcloud alpha services api-keys create \
    --display-name="$API_DISPLAY_NAME" 
export API_KEY_ID=$(
    gcloud alpha services api-keys list \
        --format="value(name)" \
        --filter "displayName=$API_DISPLAY_NAME")
gcloud services api-keys update $API_KEY_ID \
    --api-target=service=speech.googleapis.com \
    --api-target=service=texttospeech.googleapis.com \
    --api-target=service=translate.googleapis.com
export API_KEY=$(
    gcloud alpha services api-keys get-key-string $API_KEY_ID \
        --format="value(keyString)")

cat << 'EOF'

========================================================
Task 2. Create synthetic speech from text using the Text-to-Speech API
========================================================

EOF
## Refer to GSP222. 
## Access toke is used for GSP222, while API key is used here. 

cat << 'EOF' > synthesize-text.json
{
    'input':{
        'text':'Cloud Text-to-Speech API allows developers to include
           natural-sounding, synthetic human speech as playable audio in
           their applications. The Text-to-Speech API converts text or
           Speech Synthesis Markup Language (SSML) input into audio data
           like MP3 or LINEAR16 (the encoding used in WAV files).'
    },
    'voice':{
        'languageCode':'en-gb',
        'name':'en-GB-Standard-A',
        'ssmlGender':'FEMALE'
    },
    'audioConfig':{
        'audioEncoding':'MP3'
    }
}
EOF

cat << 'EOF' > tts_decode.py
import argparse
from base64 import decodebytes
import json

"""
Usage:
        python tts_decode.py --input "Filled in at lab start" \
        --output "synthesize-text-audio.mp3"

"""

def decode_tts_output(input_file, output_file):
    """ Decode output from Cloud Text-to-Speech.

    input_file: the response from Cloud Text-to-Speech
    output_file: the name of the audio file to create

    """

    with open(input_file) as input:
        response = json.load(input)
        audio_data = response['audioContent']

        with open(output_file, "wb") as new_file:
            new_file.write(decodebytes(audio_data.encode('utf-8')))

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description="Decode output from Cloud Text-to-Speech",
        formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--input',
                        help='The response from the Text-to-Speech API.',
                        required=True)
    parser.add_argument('--output',
                        help='The name of the audio file to create',
                        required=True)

    args = parser.parse_args()
    decode_tts_output(args.input, args.output)
EOF

echo '#!/bin/bash' > task2.sh
echo "export API_KEY=$API_KEY" >> task2.sh
echo "export TASK2_RESULT=$TASK2_RESULT" >> task2.sh
cat << 'EOF' >> task2.sh
curl -s -X POST \
  -H "Content-Type: application/json; charset=utf-8" \
  -d @synthesize-text.json \
  "https://texttospeech.googleapis.com/v1/text:synthesize?key=${API_KEY}" \
  > $TASK2_RESULT
source venv/bin/activate
python tts_decode.py --input "$TASK2_RESULT" --output "synthesize-text-audio.mp3"
EOF

gcloud compute scp synthesize-text.json tts_decode.py task2.sh $VM_NAME:~ \
  --project=$PROJECT_ID \
  --zone=$ZONE \
  --quiet

gcloud compute ssh my-instance \
  --project=$PROJECT_ID \
  --zone=$ZONE \
  --quiet \
  --command="chmod +x ~/task2.sh && ~/task2.sh"

gcloud compute scp VM_NAME:~/synthesize-text-audio.mp3 . \
  --project=$PROJECT_ID \
  --zone=$ZONE \
  --quiet


cat << 'EOF'

========================================================
Task 3. Perform speech to text transcription with the Cloud Speech API
========================================================

EOF
## Refer to GSP048

cat << 'EOF' > $TASK3_REQUEST
{
  "config": {
      "encoding":"FLAC",
      "languageCode": "en-US"
  },
  "audio": {
      "uri":"gs://cloud-samples-data/speech/corbeau_renard.flac"
  }
}
EOF

echo '#!/bin/bash' > task3.sh
echo "export API_KEY=$API_KEY" >> task3.sh
echo "export TASK3_REQUEST=$TASK3_REQUEST" >> task3.sh
echo "export TASK3_RESULT=$TASK3_RESULT" >> task3.sh
cat << 'EOF' >> task3.sh
rm -f $TASK3_RESULT
curl -s -X POST \
  -H "Content-Type: application/json" \
  --data-binary @"${TASK3_REQUEST}" \
  "https://speech.googleapis.com/v1/speech:recognize?key=${API_KEY}" \
  > "${TASK3_RESULT}"
echo -e "\n👉  Check ${TASK3_RESULT}\n"
cat $TASK3_RESULT
EOF

## Copy files to the VM instance
gcloud compute scp "$TASK3_REQUEST" task3.sh $VM_NAME:~ \
  --project=$PROJECT_ID \
  --zone=$ZONE \
  --quiet

gcloud compute ssh $VM_NAME \
  --project=$PROJECT_ID \
  --zone=$ZONE \
  --quiet \
  --command="chmod +x ~/task3.sh && ~/task3.sh"


cat << 'EOF'

========================================================
Task 4. Translate text with the Cloud Translation API
========================================================

EOF
## Refer to GSP049

echo '#!/bin/bash' > task4.sh
echo "export API_KEY=$API_KEY" >> task4.sh
echo "export TASK4_TEXT=$TASK4_TEXT" >> task4.sh
echo "export TASK4_RESULT=$TASK4_RESULT" >> task4.sh
cat << 'EOF' >> task4.sh
rm -f $TASK4_RESULT
curl "https://translation.googleapis.com/language/translate/v2?target=es&key=${API_KEY}&q=${TASK4_TEXT}" \
    > "${TASK4_RESULT}"
echo -e "\n👉  Check ${TASK4_RESULT}\n"
cat $TASK4_RESULT
EOF

## Copy files to the VM instance
gcloud compute scp task4.sh $VM_NAME:~ \
  --project=$PROJECT_ID \
  --zone=$ZONE \
  --quiet

gcloud compute ssh $VM_NAME \
  --project=$PROJECT_ID \
  --zone=$ZONE \
  --quiet \
  --command="chmod +x ~/task4.sh && ~/task4.sh"


cat << 'EOF'

========================================================
Task 5. Detect a language with the Cloud Translation API
========================================================

EOF
## Refer to GSP049 Task 3

echo '#!/bin/bash' > task5.sh
echo "export API_KEY=$API_KEY" >> task5.sh
echo "export TASK5_TEXT=$TASK5_TEXT" >> task5.sh
echo "export TASK5_RESULT=$TASK5_RESULT" >> task5.sh
cat << 'EOF' >> task5.sh
rm -f $TASK5_RESULT
curl -X POST "https://translation.googleapis.com/language/translate/v2/detect?key=${API_KEY}" \
    -d "q=${TASK5_TEXT}" \
    > "${TASK5_RESULT}"
echo -e "\n👉  Check ${TASK5_RESULT}\n"
cat $TASK5_RESULT
EOF

echo -e "\n✅  All done\n"
