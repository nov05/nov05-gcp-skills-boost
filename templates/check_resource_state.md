
👉 Refer to GSP647

* Make sure a role has been created.

```bash
gcloud iam roles create devops \
    --project $PROJECTID2 \
    --permissions \
    "compute.instances.create,\
compute.instances.delete,\
compute.instances.start,\
compute.instances.stop,\
compute.instances.update,\
compute.disks.create,\
compute.subnetworks.use,\
compute.subnetworks.useExternalIp,\
compute.instances.setMetadata,\
compute.instances.setServiceAccount"
until gcloud iam roles describe devops --project $PROJECTID2 >/dev/null 2>&1
do sleep 5; done
```

* Make sure roles have been binded.

```bash
gcloud projects add-iam-policy-binding $PROJECTID2 \
    --member=user:$USERID2 \
    --role=roles/iam.serviceAccountUser
until gcloud projects get-iam-policy $PROJECTID2 \
  --flatten="bindings[].members" \
  --format="value(bindings.role, bindings.members)" 2>/dev/null \
  | grep -q "roles/iam.serviceAccountUser.*$USERID2"
do sleep 5; done
```
```bash
gcloud projects add-iam-policy-binding $PROJECTID2 \
    --member=user:$USERID2 \
    --role=projects/$PROJECTID2/roles/devops
until gcloud projects get-iam-policy $PROJECTID2 \
  --flatten="bindings[].members" \
  --format="value(bindings.role, bindings.members)" 2>/dev/null \
  | grep -q "projects/$PROJECTID2/roles/devops.*$USERID2"
do sleep 5; done
```
```bash
gcloud projects add-iam-policy-binding $PROJECTID2 \
    --member serviceAccount:$SA \
    --role=roles/compute.instanceAdmin
until gcloud projects get-iam-policy "$PROJECTID2" \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:$SA AND bindings.role:roles/compute.instanceAdmin" \
  --format="value(bindings.role)" | grep -q .
do sleep 5; done
```

* Make sure a service account has been created.

```bash
gcloud iam service-accounts create devops --display-name devops
until gcloud iam service-accounts describe \
  "devops@$PROJECTID2.iam.gserviceaccount.com" >/dev/null 2>&1
do sleep 5; done
```

👉 Refer to ARC134  

* Make sure an API is enabled.

```bash
gcloud services enable aiplatform.googleapis.com \
  --project=$PROJECT_ID
until gcloud services list --enabled \
  --project=$PROJECT_ID | grep -q aiplatform.googleapis.com
do sleep 5; done
```

* Make sure a VM instance is running.

```bash
gcloud compute instances create bigquery-instance \
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
until gcloud compute ssh bigquery-instance \
    --zone=$ZONE \
    --command="echo ready" >/dev/null 2>&1; do
  sleep 5
done
```