# 🟢 GSP094 Pub/Sub: Qwik Start - Python

https://www.skills.google/games/7222/labs/44674   

```text
Task 1. Create a virtual environment
Task 2. Install the client library
Task 3. Pub/Sub - the Basics
Task 4. Create a topic
Task 5. Create a subscription
Task 6. Publish messages
Task 7. View messages
Task 8. Test your understanding
```

## 👉 Run the following command in Google Cloud Shell

```bash
rm -rf *
curl -LO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/main/bash-scripts/gsp094.sh
sudo chmod +x gsp094.sh
yes y | ./gsp094.sh 2>&1 | tee -a logs.txt
sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g' logs.txt > clean_logs.txt
```

* You can find a terminal output log sample file in this folder.  

---   

* For development only  

```bash
rm -rf *
curl -LO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/dev/bash-scripts/gsp094.sh
sudo chmod +x gsp094.sh
yes y | ./gsp094.sh 2>&1 | tee -a logs.txt
sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g' logs.txt > clean_logs.txt
```

* Delete Pub/Sub objects

```bash
gcloud pubsub subscriptions delete MySub
gcloud pubsub topics delete MyTopic
```

* Client library  
  https://github.com/googleapis/python-pubsub/tree/main/samples/snippets    
  [publisher.py](https://github.com/googleapis/python-pubsub/blob/main/samples/snippets/publisher.py), [subscriber.py](https://github.com/googleapis/python-pubsub/blob/main/samples/snippets/subscriber.py)  