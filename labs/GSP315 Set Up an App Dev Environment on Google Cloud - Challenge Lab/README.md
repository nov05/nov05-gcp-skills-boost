# 🟢 GSP315 Set Up an App Dev Environment on Google Cloud: Challenge Lab

https://www.skills.google/games/7222/labs/44675

```text
Task 1. Create a bucket
Task 2. Create a Pub/Sub topic
Task 3. Create the thumbnail Cloud Run Function
Task 4. Remove the previous cloud engineer
```

## 👉 Run the following command in Google Cloud Shell

```bash
rm -rf *
curl -LO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/main/bash-scripts/gsp315.sh
sudo chmod +x gsp315.sh
./gsp315.sh 2>&1 | tee -a logs.txt
sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g' logs.txt > clean_logs.txt
```

<br>  

---   

* For development

```bash
rm -rf *
curl -LO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/dev/bash-scripts/gsp315.sh
sudo chmod +x gsp315.sh
./gsp315.sh 2>&1 | tee -a logs.txt
sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g' logs.txt > clean_logs.txt
```