# 🟢 GSP062 Building a High-throughput VPN

https://www.skills.google/focuses/641?parent=catalog

```text
Task 1. Create the cloud VPC  
Task 2. Create the on-prem VPC    
Task 3. Create VPN gateways
Task 4. Create a route-based VPN tunnel between local and Google Cloud networks  
Task 5. Test throughput over VPN
```

## 👉 Run the following commands in Google Cloud Shell

```bash
rm -rf *
curl -LO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/main/bash-scripts/gsp062.sh
sudo chmod +x gsp062.sh
yes y | ./gsp062.sh 2>&1 | tee -a logs.txt
sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g' logs.txt > clean_logs.txt
```

* After running the script, check the terminal output in `clean_logs.txt`.   
  You can find a sample log file in this folder.  
