# 🟢 GSP864 Redacting Critical Data with Sensitive Data Protection

https://www.skills.google/games/7224/labs/44702

```text
Task 1. Clone the repo and enable APIs
Task 2. Inspect strings and files
Task 3. De-identification
Task 4. Redact strings and images
```  

## 👉 Run the following command in Google Cloud Shell

```bash
rm -rf *
curl -LO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/main/bash-scripts/gsp864.sh
sudo chmod +x gsp864.sh
yes y | ./gsp864.sh 2>&1 | tee -a logs.txt
sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g' logs.txt > clean_logs.txt
```