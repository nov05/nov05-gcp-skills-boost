# 🟢 GSP107 Cloud Data Loss Prevention API: Qwik Start

https://www.skills.google/games/7224/labs/44701

```text
TASK 1: Inspect a string for sensitive information
TASK 2: Redacting sensitive data from text content
```

## 👉 Run the following command in Google Cloud Shell

```bash
rm -rf *
curl -LO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/main/bash-scripts/gsp107.sh
sudo chmod +x gsp107.sh
yes y | ./gsp107.sh 2>&1 | tee -a logs.txt
sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g' logs.txt > clean_logs.txt
```