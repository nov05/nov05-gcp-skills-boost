# 🟢 GSP1317 Establish VPC to VPC Connectivity using NCC

Game Aug 2026: https://www.skills.google/games/7397/labs/45413  

```text
Task 1. Create a hub
Task 2. Configure VPCs as NCC spokes
Task 3. Verify IPv4 Data Path Connectivity
Task 4. Set up Private Service Connect
Task 5. Connect to Cloud SQL via Private Service Connect
Task 6. Delete resources
```

## 👉 Run the following command in Google Cloud Shell

```bash
rm -rf *
curl -LO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/main/bash-scripts/gsp1317.sh
sudo chmod +x gsp1317.sh
yes y | ./gsp1317.sh 2>&1 | tee -a logs.txt
sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g' logs.txt > clean_logs.txt
```

2026-08-06 `gsp1317.sh` was created and tested.