## 👉 For development

```bash
rm -rf *
curl -LO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/dev/bash-scripts/gsp049.sh
sudo chmod +x gsp049.sh
./gsp049.sh 2>&1 | tee -a logs.txt
sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g' logs.txt > gsp049_clean_logs.txt
```

## 👉 Logs

* 2026-06-09 Script `gsp049.sh` created and tested