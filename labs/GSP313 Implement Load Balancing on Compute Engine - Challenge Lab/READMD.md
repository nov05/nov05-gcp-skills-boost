# 🟢 GSP313 Implement Load Balancing on Compute Engine: Challenge Lab

https://www.skills.google/games/7225/labs/44711   


```text
Task 1. Create multiple web server instances
Task 2. Configure the load balancing service
Task 3. Create an HTTP load balancer
```

## 👉 Run the following command in Google Cloud Shell

```bash
rm -rf *
curl -LO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/main/bash-scripts/gsp313.sh
sudo chmod +x gsp313.sh
./gsp313.sh 2>&1 | tee -a logs.txt
sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g' logs.txt > clean_logs.txt
```