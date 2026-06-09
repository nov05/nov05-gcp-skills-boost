## Created by nov05, 2026-05-15

## Download script
rm -rf *
curl -LO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/main/bash-scripts/gsp642.sh
sudo chmod +x gsp642.sh

## If youare not using the spinner function in the script...
yes y | ./gsp642.sh 2>&1 | tee -a logs.txt
sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g' logs.txt > clean_logs.txt



## If you are using the spinner function in the script...
./gsp642.sh 2>&1 | tee -a logs.txt
perl -pe '
s/\e\[[0-9;]*[A-Za-z]//g;
s/\x08//g;
s/\r//g;
' logs.txt | grep -vE '\[[/|\\-]\]' > clean_logs.txt

