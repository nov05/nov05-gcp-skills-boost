#!/bin/bash
## Created by nov05, 2026-06-09  

## Get project id, project number, region, zone
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID \
  --format='value(projectNumber)')
export REGION=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-region])")
export ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
gcloud config set project $PROJECT_ID  
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE
echo
echo "🔹  User: $USER"
echo "🔹  Project ID: $PROJECT_ID"
echo "🔹  Project number: $PROJECT_NUMBER"
echo "🔹  Region: $REGION"
echo "🔹  Zone: $ZONE"
echo
gcloud auth list

cat << 'EOF'

========================================================
Task 1: Enable the Text-to-Speech API
========================================================

EOF

gcloud services enable texttospeech.googleapis.com \
    --project=$PROJECT_ID
until gcloud services list --enabled \
  --project=$PROJECT_ID | grep -q texttospeech.googleapis.com
do sleep 5; done


cat << 'EOF'

========================================================
Task 2: Create a virtual environment
========================================================

EOF

sudo apt-get install -y virtualenv
python3 -m venv venv
source venv/bin/activate

cat << 'EOF'

========================================================
Task 3: Create a service account
========================================================

EOF

export SA="tts-qwiklab@$PROJECT_ID.iam.gserviceaccount.com"
gcloud iam service-accounts describe "$SA" >/dev/null 2>&1 || \
gcloud iam service-accounts create tts-qwiklab
until gcloud iam service-accounts describe \
  "tts-qwiklab@$PROJECT_ID.iam.gserviceaccount.com" >/dev/null 2>&1
do sleep 5; done

## Authenticating by using local Application Default Credentials
gcloud iam service-accounts keys create tts-qwiklab.json \
    --iam-account tts-qwiklab@$PROJECT_ID.iam.gserviceaccount.com
export GOOGLE_APPLICATION_CREDENTIALS=tts-qwiklab.json
gcloud auth application-default login --quiet
gcloud auth application-default set-quota-project $PROJECT_ID --quiet

cat << 'EOF'

========================================================
Task 4: Get a list of available voices
========================================================

EOF

unset GOOGLE_APPLICATION_CREDENTIALS
gcloud auth application-default revoke -q
export TOKEN=$(gcloud auth print-access-token)

echo -e "\n👉  List the voices available when you use the Text-to-Speech API to create synthetic speech.\n"
curl -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json; charset=utf-8" \
    "https://texttospeech.googleapis.com/v1/voices"

echo -e "\n👉  Scope the results returned from the API to just a single language code."
curl -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json; charset=utf-8" \
    "https://texttospeech.googleapis.com/v1/voices?language_code=en"


cat << 'EOF'

========================================================
Task 5: Create synthetic speech from text
========================================================

EOF

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

echo -e "\n👉  Build the request.\n"
curl -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json; charset=utf-8" \
  -d @synthesize-text.json "https://texttospeech.googleapis.com/v1/text:synthesize" \
  > synthesize-text.txt

cat << 'EOF' > tts_decode.py
import argparse
from base64 import decodebytes
import json

"""
Usage:
        python tts_decode.py --input "synthesize-text.txt" \
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

echo -e "\n👉  Translate the response. Create the audio file synthesize-text-audio.mp3.\n"
python tts_decode.py --input "synthesize-text.txt" --output "synthesize-text-audio.mp3"


cat << 'EOF'

========================================================
Task 6: Create synthetic speech from SSML
========================================================

EOF
## Speech Synthesis Markup Language (SSML)

cat << 'EOF' > synthesize-ssml.json
{
    'input':{
        'ssml':'<speak><s>
           <emphasis level="moderate">Cloud Text-to-Speech API</emphasis>
           allows developers to include natural-sounding
           <break strength="x-weak"/>
           synthetic human speech as playable audio in their
           applications.</s>
           <s>The Text-to-Speech API converts text or
           <prosody rate="slow">Speech Synthesis Markup Language</prosody>
           <say-as interpret-as=\"characters\">SSML</say-as>
           input into audio data
           like <say-as interpret-as=\"characters\">MP3</say-as> or
           <sub alias="linear sixteen">LINEAR16</sub>
           <break strength="weak"/>
           (the encoding used in
           <sub alias="wave">WAV</sub> files).</s></speak>'
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

curl -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json; charset=utf-8" \
  -d @synthesize-ssml.json "https://texttospeech.googleapis.com/v1/text:synthesize" \
  > synthesize-ssml.txt

echo -e "\n👉  Create the audio file synthesize-ssml-audio.mp3.\n"
python tts_decode.py --input "synthesize-ssml.txt" --output "synthesize-ssml-audio.mp3"


cat << 'EOF'

========================================================
Task 7: Configure audio output and device profiles
========================================================

EOF

cat << 'EOF' > synthesize-with-settings.json
{
    'input':{
        'text':'The Text-to-Speech API is ideal for any application
          that plays audio of human speech to users. It allows you
          to convert arbitrary strings, words, and sentences into
          the sound of a person speaking the same things.'
    },
    'voice':{
        'languageCode':'en-us',
        'name':'en-GB-Standard-A',
        'ssmlGender':'FEMALE'
    },
    'audioConfig':{
      'speakingRate': 1.15,
      'pitch': -2,
      'audioEncoding':'OGG_OPUS',
      'effectsProfileId': ['headphone-class-device']
    }
}
EOF

curl -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json; charset=utf-8" \
  -d @synthesize-with-settings.json "https://texttospeech.googleapis.com/v1beta1/text:synthesize" \
  > synthesize-with-settings.txt

echo -e "\n👉  Create the audio file synthesize-with-settings-audio.mp3.\n"
python3 tts_decode.py \
    --input "synthesize-with-settings.txt" \
    --output "synthesize-with-settings-audio.mp3"


echo -e "\n✅  All done\n"
