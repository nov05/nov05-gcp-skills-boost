## Created by nov05, 2026-06-12
## Refer to GSP092

echo -e "\n👉  Enabling services...\n"
gcloud services enable \
  run.googleapis.com \
  artifactregistry.googleapis.com \
  cloudbuild.googleapis.com 
until enabled=$(gcloud services list --enabled --project=$PROJECT_ID); \
  echo "$enabled" | grep -q run.googleapis.com && \
  echo "$enabled" | grep -q artifactregistry.googleapis.com && \
  echo "$enabled" | grep -q cloudbuild.googleapis.com
do sleep 5; done

mkdir myfunc && cd myfunc
cat > index.js << 'EOF'
const functions = require('@google-cloud/functions-framework');
functions.http('helloHttp', (req, res) => {
  res.set('Content-Type', 'text/plain');
  res.send(`Hello ${req.query.name || req.body.name || 'World'}!`);
});
EOF
cat > package.json << 'EOF'
{
  "dependencies": {
    "@google-cloud/functions-framework": "^3.0.0"
  }
}
EOF
cd ..

echo -e "\n👉  Deploying Cloud Run function 'helloworld'...\n"
## It may need retry a couple of times.
for i in {1..10}; do
  gcloud functions deploy helloworld \
    --gen2 \
    --runtime=nodejs22 \
    --region=$REGION \
    --source=./myfunc \
    --entry-point=helloHttp \
    --trigger-http \
    --allow-unauthenticated \
    --max-instances=5 \
    --timeout=300 \
    --memory=512Mi \
    --cpu=1 \
    --concurrency=80 && break
  echo "Retry in 30 seconds..."
  sleep 30
done
gcloud run services update helloworld \
  --region=$REGION \
  --execution-environment gen2
echo -e "\n👉  Check Cloud Run funcion 'helloworld' at"  
echo -e "https://console.cloud.google.com/run/detail/${REGION}/helloworld/source?project=$PROJECT_ID"