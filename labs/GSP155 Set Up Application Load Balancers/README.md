# 🟢 GSP155 Set Up Application Load Balancers

https://www.skills.google/games/7225/labs/44709

```text
Task 1. Set the default region and zone for all resources
Task 2. Create multiple web server instances
Task 3. Create an Application Load Balancer
Task 4. Test traffic sent to your instances
```

## 👉 Run the following command in Google Cloud Shell

```bash
rm -rf *
curl -LO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/main/bash-scripts/gsp155.sh
sudo chmod +x gsp155.sh
yes y | ./gsp155.sh 2>&1 | tee -a logs.txt
sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g' logs.txt > clean_logs.txt
```