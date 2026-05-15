# 🟢 App Engine: Qwik Start - PHP (GSP069) 

https://www.skills.google/games/7171/labs/44404

```text
Task 1. Enable Google App Engine Admin API
Task 2. Download the Hello World app
Task 3. Deploy your app
Task 4. View your application
Task 5. Make a change
Task 6. Test your knowledge
```

```bash
git clone https://github.com/GoogleCloudPlatform/php-docs-samples.git
cd php-docs-samples/appengine/standard/helloworld
sed -i 's/^runtime: php.*/runtime: php83/' app.yaml
grep runtime app.yaml
printf '1\n' | gcloud app create
gcloud app deploy --quiet
gcloud app browse
```

```bash
rm -f gsp069.sh
curl -LO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/main/bash-scripts/gsp069.sh
chmod +x gsp069.sh
./gsp069.sh
```