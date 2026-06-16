# 🟢 GSP323 Prepare Data for ML APIs on Google Cloud: Challenge Lab

https://www.skills.google/games/7224/labs/44699

```text
Task 1. Run a simple Dataflow job
Task 2. Run a simple Managed Apache Spark job
Task 3. Use the Google Cloud Speech-to-Text API
Task 4. Use the Cloud Natural Language API
```

```bash
rm -rf *
curl -LO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/main/bash-scripts/gsp323.sh
sudo chmod +x gsp323.sh
./gsp323.sh 2>&1 | tee -a logs.txt
sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g' logs.txt > clean_logs.txt
```