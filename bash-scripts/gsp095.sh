#!/bin/bash
## Created by nov05, 2026-06-10  


cat << 'EOF'

========================================================
Task 1. Pub/Sub topics
========================================================

EOF

gcloud pubsub topics create myTopic
gcloud pubsub topics create Test1
gcloud pubsub topics create Test2
gcloud pubsub topics list

gcloud pubsub topics delete Test1
gcloud pubsub topics delete Test2
gcloud pubsub topics list

cat << 'EOF'

========================================================
Task 2. Pub/Sub subscriptions
========================================================

EOF

gcloud  pubsub subscriptions create --topic myTopic mySubscription
gcloud  pubsub subscriptions create --topic myTopic Test1
gcloud  pubsub subscriptions create --topic myTopic Test2
gcloud pubsub topics list-subscriptions myTopic

gcloud pubsub subscriptions delete Test1
gcloud pubsub subscriptions delete Test2
gcloud pubsub topics list-subscriptions myTopic

cat << 'EOF'

========================================================
Task 3. Pub/Sub publishing and pulling a single message
========================================================

EOF

gcloud pubsub topics publish myTopic --message "Hello"
gcloud pubsub topics publish myTopic --message "Publisher's name is Joey (dog)"
gcloud pubsub topics publish myTopic --message "Publisher likes to eat dog treats"
gcloud pubsub topics publish myTopic --message "Publisher thinks Pub/Sub is awesome"

gcloud pubsub subscriptions pull mySubscription --auto-ack


cat << 'EOF'

========================================================
Task 4. Pub/Sub pulling all messages from subscriptions
========================================================

EOF

gcloud pubsub topics publish myTopic --message "Publisher is starting to get the hang of Pub/Sub"
gcloud pubsub topics publish myTopic --message "Publisher wonders if all messages will be pulled"
gcloud pubsub topics publish myTopic --message "Publisher will have to test to find out"

gcloud pubsub subscriptions pull mySubscription --limit=3

echo -e "\n✅  All done\n"