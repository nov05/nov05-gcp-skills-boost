# 🟢 GSP338 Monitor and Log with Google Cloud Observability: Challenge Lab

https://www.skills.google/games/7222/labs/44680  
https://www.skills.google/course_templates/749/labs/594584  

```text
Task 1. Configure Cloud Monitoring
Task 2. Configure a Compute Instance to generate Custom Cloud Monitoring metrics
Task 3. Create a custom metric using Cloud Operations logging events
Task 4. Add custom metrics to the Media Dashboard in Cloud Operations Monitoring
Task 5. Create a Cloud Operations alert based on the rate of high resolution video file uploads
```

## 👉 Run the following commands in Google Cloud Shell.

```bash
rm -rf *
curl -LO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/main/bash-scripts/gsp338.sh
sudo chmod +x gsp338.sh
./gsp338.sh 2>&1 | tee -a logs.txt
sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g' logs.txt > clean_logs.txt
```