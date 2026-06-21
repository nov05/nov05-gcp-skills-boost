# 🟢 GSP539 Build Global and Regional Load Balancing Solutions: Challenge Lab

https://www.skills.google/games/7225/labs/44716   
https://www.skills.google/course_templates/1558/labs/612203   

```text
Task 1. Secure internal transaction processor (regional internal proxy NLB)
Task 2. Global external market data feed (global external application Load Balancer)
Task 3. Test failover and global distribution
```

## 👉 Run the following command in Google Cloud Shell

```bash
rm -rf *
curl -LO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/main/bash-scripts/gsp539.sh
sudo chmod +x gsp539.sh
./gsp539.sh 2>&1 | tee -a logs.txt
sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g' logs.txt > clean_logs.txt
```

* This lab can be fully automated by the Bash script.    
* A terminal output log sample file can be found in this folder.    

## Additional information  

* **Task 1**, Regional internal Network Load Balancer with regional access (glocal access in the figure)     
  https://docs.cloud.google.com/load-balancing/docs/l7-internal/setting-up-l7-internal   
  <img src="https://raw.githubusercontent.com/nov05/pictures/f966f106ed1af62c448b8ec7426b0a5d7fba91a8/gcp-skills-boost/gsp539/proxy-ilb-global-access-arch.svg" width=800>  

* **Task 2**, External Application Load Balancer with a managed instance group (MIG) backend   
  https://docs.cloud.google.com/load-balancing/docs/https/setup-global-ext-https-compute  
  <img src="https://raw.githubusercontent.com/nov05/pictures/ca42485c1ab8d50d02cbfe5a6cdcb0107dc17262/gcp-skills-boost/gsp539/https-load-balancer-simple-gxlb.svg" width=800>  

