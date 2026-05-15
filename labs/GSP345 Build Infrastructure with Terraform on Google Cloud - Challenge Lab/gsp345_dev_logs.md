## 👉 For development

```bash
rm -f gsp345.sh
curl -LO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/dev/bash-scripts/gsp345.sh
chmod +x gsp345.sh
./gsp345.sh 2>&1 | tee -a logs.txt
sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g' logs.txt > clean_logs.txt
```

  
## 👉 Logs   

* 2026-05-14 ✅ Tested the original script. 