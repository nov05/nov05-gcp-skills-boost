# 🟢 GSP092 Monitoring and Logging for Cloud Run Functions

https://www.skills.google/games/7222/labs/44679

```text
Task 1. Viewing Cloud Run function logs & metrics in Cloud Monitoring
Task 2. Create a logs-based metric
Task 3. Metrics Explorer
Task 4. Create charts on the Monitoring Overview window
Task 5. Test your understanding
```

## 👉 Run the following commands in Google Cloud Shell. 

```bash
rm -rf *
curl -LO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/main/bash-scripts/gsp092.sh
sudo chmod +x gsp092.sh
./gsp092.sh 2>&1 | tee -a logs.txt
sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g' logs.txt > clean_logs.txt
```
