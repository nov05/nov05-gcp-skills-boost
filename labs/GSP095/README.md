# 🟢 GSP095

https://www.skills.google/games/7222/labs/44673

```text
Task 1. Pub/Sub topics
Task 2. Pub/Sub subscriptions
Task 3. Pub/Sub publishing and pulling a single message
Task 4. Pub/Sub pulling all messages from subscriptions
```

```bash
rm -rf *
curl -LO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/main/bash-scripts/gsp095.sh
sudo chmod +x gsp095.sh
./gsp095.sh 2>&1 | tee -a logs.txt
sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g' logs.txt > clean_logs.txt
```