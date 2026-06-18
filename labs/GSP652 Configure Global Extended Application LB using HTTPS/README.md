# 🟢 GSP652 Configure Global Extended Application LB using HTTPS  

https://www.skills.google/games/7225/labs/44714   

```text
Task 1. Create Instance Groups
Task 2. Create a health check
Task 3. Create a backend service
Task 4. Test and verify Load Balancing
Task 5. Understand health checks
Task 6. Clean up
```

## 👉 Run the following command in Google Cloud Shell

```bash
rm -rf *
curl -LO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/main/bash-scripts/gsp652.sh
sudo chmod +x gsp652.sh
yes y | ./gsp652.sh 2>&1 | tee -a logs.txt
sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g' logs.txt > clean_logs.txt
```