## Refer to GSP062
gcloud compute instances add-metadata "my-instance" \
  --zone=$ZONE \
  --metadata enable-oslogin=FALSE

## Or disable OS login after instance creation
gcloud compute instances add-metadata "my-instance" \
  --zone=$ZONE \
  --metadata enable-oslogin=FALSE