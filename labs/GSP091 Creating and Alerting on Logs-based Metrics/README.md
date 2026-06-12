# 🟢 GSP091 Creating and Alerting on Logs-based Metrics

https://www.skills.google/games/7222/labs/44678

```text
Task 1. Deploy a GKE cluster
Task 2. Create a log-based alert
Task 3. Create a Docker repository
Task 4. Deploy a simple application that emits metrics
Task 5. Create a log-based metric
Task 6. Create a metrics-based alert
Task 7. Generate some errors
```

## 👉 Run the following commands in Google Cloud Shell.

```bash
rm -rf *
curl -LO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/main/bash-scripts/gsp091.sh
sudo chmod +x gsp091.sh
./gsp091.sh 2>&1 | tee -a logs.txt
sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g' logs.txt > clean_logs.txt
```