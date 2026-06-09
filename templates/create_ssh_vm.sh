## Refer to GSP199
gcloud compute instances create my-instance \
  --project="$PROJECT_ID" \
  --zone="$ZONE" \
  --machine-type="e2-medium" \
  --subnet="default" \
  --service-account="bigquery-qwiklab@$PROJECT_ID.iam.gserviceaccount.com" \
  --scopes="https://www.googleapis.com/auth/cloud-platform" \
  --image-family="debian-12" \
  --image-project="debian-cloud" \
  --boot-disk-size="10GB" \
  --boot-disk-type="pd-standard" \
  --metadata=enable-oslogin=FALSE
until gcloud compute my-instance \
    --zone=$ZONE \
    --command="echo ready" >/dev/null 2>&1; do
  sleep 5
done

cat > my-query.sh << 'EOF'
#!/bin/bash
## Install required packages
sudo apt-get update -qq
EOF

gcloud compute scp my-query.sh my-instance:/tmp \
  --project=$PROJECT_ID \
  --zone=$ZONE \
  --quiet

gcloud compute ssh my-instance \
  --project=$PROJECT_ID \
  --zone=$ZONE \
  --quiet \
  --command="chmod +x /tmp/my-query.sh && /tmp/my-query.sh"
