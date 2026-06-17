# 🟢 GSP041 Use an Internal Application Load Balancer

https://www.skills.google/games/7225/labs/44710  

```text
Task 1. Create a virtual environment
Task 2. Create a backend managed instance group
Task 3. Set up the internal load balancer
Task 4. Test the load balancer
Task 5. Create a public-facing web server
```

## 👉 Run the following command in Google Cloud Shell

```bash
rm -rf *
curl -LO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/main/bash-scripts/gsp041.sh
sudo chmod +x gsp041.sh
./gsp041.sh 2>&1 | tee -a logs.txt
sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g' logs.txt > clean_logs.txt
```