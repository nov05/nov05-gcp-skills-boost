#!/bin/bash
## Created by nov05, 2026-06-10 

cat << 'EOF'

========================================================
Task 1. Create a virtual environment
========================================================

EOF

sudo apt-get install -y virtualenv
python3 -m venv venv
source venv/bin/activate

cat << 'EOF'

========================================================
Task 2. Install the client library
========================================================

EOF

pip install --upgrade google-cloud-pubsub
git clone https://github.com/googleapis/python-pubsub.git
cd python-pubsub/samples/snippets

cat << 'EOF'

========================================================
Task 3. Pub/Sub - the Basics
========================================================

EOF


cat << 'EOF'

========================================================
Task 4. Create a topic
========================================================

EOF

echo $GOOGLE_CLOUD_PROJECT
cat publisher.py
python publisher.py -h

python publisher.py $GOOGLE_CLOUD_PROJECT create MyTopic
python publisher.py $GOOGLE_CLOUD_PROJECT list

cat << 'EOF'

========================================================
Task 5. Create a subscription
========================================================

EOF

python subscriber.py $GOOGLE_CLOUD_PROJECT create MyTopic MySub
python subscriber.py $GOOGLE_CLOUD_PROJECT list-in-project

cat << 'EOF'

========================================================
Task 6. Publish messages
========================================================

EOF

gcloud pubsub topics publish MyTopic --message "Hello"
gcloud pubsub topics publish MyTopic --message "Publisher's name is Joey (dog)"
gcloud pubsub topics publish MyTopic --message "Publisher likes to eat dog treats"
gcloud pubsub topics publish MyTopic --message "Publisher thinks Pub/Sub is awesome"

cat << 'EOF'

========================================================
Task 7. View messages
========================================================

EOF

python subscriber.py $GOOGLE_CLOUD_PROJECT receive MySub

cat << 'EOF'

========================================================
Task 8. Test your understanding
========================================================

1. Google Cloud Pub/Sub service allows applications to exchange messages reliably, quickly, and asynchronously.
  True
2. A _____ is a shared string that allows applications to connect with one another.
  topic
EOF


echo -e "\n✅  All done\n"
