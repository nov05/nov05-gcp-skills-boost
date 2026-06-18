# 🟢 GSP636 Implement Regional Internal Proxy NLB

https://www.skills.google/games/7225/labs/44713

```text
Task 1. Configure the Network and Subnets
Task 2. Create Firewall Rules
Task 3. Create backend Managed Instance Groups (MIGs)
Task 4. Configure the Load Balancer (internal IP and proxy rules)
Task 5. Test the load balancer
(Optional) Task 6. Practice your skills
```

## 👉 Run the following command in Google Cloud Shell

```bash
rm -rf *
curl -LO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/main/bash-scripts/gsp636.sh
sudo chmod +x gsp636.sh
yes y | ./gsp636.sh 2>&1 | tee -a logs.txt
sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g' logs.txt > clean_logs.txt
```