# 🟢 GSP528 Connecting Cloud Networks with NCC: Challenge Lab

Course: https://www.skills.google/course_templates/1364  
Game Aug 2026: https://www.skills.google/games/7397/labs/45415   

```text
Task 1. Connect 2 On-prem VPCs with NCC
Task 2. Connect VPC to VPC
Task 3. Connect VPC to On-prem
```

* In this lab you'll use the **Network Connectivity Center (NCC)** to connect cloud and on-prem networks.   
  For this lab you have several resources provided:   

  <img src="https://cdn.qwiklabs.com/f%2FrYkUz2QOROG4tS2AolpxthW2GglI3KQRCq4QYjKIA%3D" width=600>  

* You will use NCC to make several network connections that, in the end, will look like the diagram below:  

  <img src="https://cdn.qwiklabs.com/vQ4dtySymq6rjFR%2BINu1D69W38uFYqwLf6Hxar5awlw%3D" width=600>  

## 👉 Run the following command in Google Cloud Shell

```bash
rm -rf *
curl -LO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/main/bash-scripts/gsp528.sh
sudo chmod +x gsp528.sh
yes y | ./gsp528.sh 2>&1 | tee -a logs.txt
sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g' logs.txt > clean_logs.txt
```

* 2026-08-07 `gsp528.sh` was created and tested. 