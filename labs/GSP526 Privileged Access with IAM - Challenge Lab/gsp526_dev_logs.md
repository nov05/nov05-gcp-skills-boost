


## Tips

```bash
(qwiklabs-gcp-03-7fd40db177bb)$ gcloud logging read \
'protoPayload.serviceName="privilegedaccessmanager.googleapis.com" AND protoPayload.resourceName:"pam-entitlement"' \
  --project=$PROJECT_ID \
  --limit=20 \
  --format="table(timestamp, protoPayload.methodName, protoPayload.authenticationInfo.principalEmail)"
  
TIMESTAMP: 2026-08-06T17:31:29.450567472Z
METHOD_NAME: google.cloud.privilegedaccessmanager.v1.PrivilegedAccessManager.DeleteEntitlement
PRINCIPAL_EMAIL: student-02-342948790472@qwiklabs.net

TIMESTAMP: 2026-08-06T17:31:23.413505335Z
METHOD_NAME: google.cloud.privilegedaccessmanager.v1.PrivilegedAccessManager.DeleteEntitlement
PRINCIPAL_EMAIL: student-02-342948790472@qwiklabs.net

TIMESTAMP: 2026-08-06T17:30:16.464433475Z
METHOD_NAME: google.cloud.privilegedaccessmanager.v1.PrivilegedAccessManager.RevokeGrant
PRINCIPAL_EMAIL: student-02-07bf1bc23612@qwiklabs.net

TIMESTAMP: 2026-08-06T17:30:14.375895778Z
METHOD_NAME: google.cloud.privilegedaccessmanager.v1.PrivilegedAccessManager.RevokeGrant
PRINCIPAL_EMAIL: student-02-07bf1bc23612@qwiklabs.net

TIMESTAMP: 2026-08-06T17:29:33.166600259Z
METHOD_NAME: PAMActivateGrant
PRINCIPAL_EMAIL: 

TIMESTAMP: 2026-08-06T17:29:31.974565974Z
METHOD_NAME: google.cloud.privilegedaccessmanager.v1.PrivilegedAccessManager.ApproveGrant
PRINCIPAL_EMAIL: student-02-07bf1bc23612@qwiklabs.net

TIMESTAMP: 2026-08-06T17:29:04.227731496Z
METHOD_NAME: google.cloud.privilegedaccessmanager.v1.PrivilegedAccessManager.CreateGrant
PRINCIPAL_EMAIL: student-02-342948790472@qwiklabs.net

TIMESTAMP: 2026-08-06T17:28:04.086095706Z
METHOD_NAME: google.cloud.privilegedaccessmanager.v1alpha.PrivilegedAccessManager.UpdateEntitlement
PRINCIPAL_EMAIL: student-02-342948790472@qwiklabs.net

TIMESTAMP: 2026-08-06T17:28:02.530481428Z
METHOD_NAME: google.cloud.privilegedaccessmanager.v1alpha.PrivilegedAccessManager.SetIamPolicy
PRINCIPAL_EMAIL: student-02-342948790472@qwiklabs.net

TIMESTAMP: 2026-08-06T17:27:58.252704454Z
METHOD_NAME: google.cloud.privilegedaccessmanager.v1alpha.PrivilegedAccessManager.UpdateEntitlement
PRINCIPAL_EMAIL: student-02-342948790472@qwiklabs.net

TIMESTAMP: 2026-08-06T17:27:07.690586725Z
METHOD_NAME: google.cloud.privilegedaccessmanager.v1.PrivilegedAccessManager.CreateEntitlement
PRINCIPAL_EMAIL: student-02-342948790472@qwiklabs.net

TIMESTAMP: 2026-08-06T17:27:06.049791483Z
METHOD_NAME: google.cloud.privilegedaccessmanager.v1alpha.PrivilegedAccessManager.SetIamPolicy
PRINCIPAL_EMAIL: student-02-342948790472@qwiklabs.net
student_02_342948790472@cloudshell:~ (qwiklabs-gcp-03-7fd40db177bb)$ 
```


```bash
gcloud pam entitlements describe pam-entitlement \
  --project=$PROJECT_ID \
  --location=global \
  --format="yaml(maxRequestDuration)"

Parsed [entitlement] resource: projects/qwiklabs-gcp-02-4905ed7511ca/locations/global/entitlements/pam-entitlement
maxRequestDuration: 14400s
```


```bash
gcloud pam entitlements create pam-entitlement \
  --project=$PROJECT_ID \
  --location=global \
  --entitlement-file=entitlement.yaml

Parsed [entitlement] resource: projects/qwiklabs-gcp-02-4905ed7511ca/locations/global/entitlements/pam-entitlement
Create request issued for: [pam-entitlement]
Waiting for operation [projects/qwiklabs-gcp-02-4905ed7511ca/locations/global/o
perations/operation-1786035258158-65863bd1e6f26-6f7ad9ec-1865293f] to complete.
..done.                                                                        
Created entitlement [pam-entitlement].
approvalWorkflow:
    - approvalsNeeded: 1
      approvers:
      - principals:
        - user:student-04-356fd5c3280a@qwiklabs.net
createTime: '2026-08-06T16:54:21.017747191Z'
eligibleUsers:
- principals:
  - user:student-03-1a19ff0b89af@qwiklabs.net
etag: '"N2ZlZWQzOGQtZDc3YS00YTlkLWE2MGItZDEzOWUxZTczNDlh"'
maxRequestDuration: 36000s
name: projects/qwiklabs-gcp-02-4905ed7511ca/locations/global/entitlements/pam-entitlement
privilegedAccess:
  gcpIamAccess:
    resource: //cloudresourcemanager.googleapis.com/projects/qwiklabs-gcp-02-4905ed7511ca
    resourceType: cloudresourcemanager.googleapis.com/Project
    roleBindings:
    - role: roles/compute.admin
requesterJustificationConfig:
  notMandatory: {}
state: AVAILABLE
updateTime: '2026-08-06T16:54:24.328604Z'
```

```bash
student_03_1a19ff0b89af@cloudshell:~ (qwiklabs-gcp-02-4905ed7511ca)$ gcloud projects get-ancestors $PROJECT_ID
ID: qwiklabs-gcp-02-4905ed7511ca
TYPE: project

ID: 125430737939
TYPE: folder

ID: 474147567761
TYPE: folder

ID: 365352270458
TYPE: folder

ID: 616463121992
TYPE: organization
```