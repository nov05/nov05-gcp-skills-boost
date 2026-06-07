## Refer to GSP062
gcloud compute instances add-metadata "my-instance" \
  --zone=$ZONE \
  --metadata enable-oslogin=FALSE