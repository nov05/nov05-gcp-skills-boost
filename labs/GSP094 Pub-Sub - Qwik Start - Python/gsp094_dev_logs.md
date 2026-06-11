## 👉 For development

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