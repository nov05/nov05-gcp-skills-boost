# 🟢 **GSP199 Service Accounts and Roles: Fundamentals**

https://www.skills.google/games/7223/labs/44684

## 👉 Run the following commands in Cloud Shell.

```bash
rm -rf *
curl -LO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/main/bash-scripts/gsp199.sh
sudo chmod +x gsp199.sh
yes y | ./gsp199.sh 2>&1 | tee -a logs.txt
sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g' logs.txt > clean_logs.txt
```

* Check the sample terminal output in `gsp199_clean_logs.txt`.