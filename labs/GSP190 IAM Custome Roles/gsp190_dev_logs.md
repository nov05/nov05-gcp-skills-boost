## 👉 For development

```bash
rm -rf *
curl -LO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/dev/bash-scripts/gsp190.sh
sudo chmod +x gsp190.sh
yes y | ./gsp190.sh 2>&1 | tee -a logs.txt
sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g' logs.txt > clean_logs.txt
```

## 👉 Logs:

* 2026-06-08 script `gsp190.sh` created.