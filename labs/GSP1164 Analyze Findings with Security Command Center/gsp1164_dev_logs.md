
## 👉 **Logs**

The lab is complete, but it may not be fully automated by the Bash script.  


## **Issues**  

#### 🟢⚠️

```bash
student_04_607ca9b43029@cloudshell:~ (qwiklabs-gcp-01-bf13749f7eb0)$ bq ls continuous_export_dataset

  tableId    Type    Labels      Time Partitioning              Clustered Fields           
 ---------- ------- -------- ------------------------- ----------------------------------- 
  findings   TABLE            DAY (field: event_time)   source_id, finding_id, event_time  
student_04_607ca9b43029@cloudshell:~ (qwiklabs-gcp-01-bf13749f7eb0)$ bq query --apilog=/dev/null --use_legacy_sql=false  "SELECT finding_id,event_time,finding.category FROM continuous_export_dataset.findings"
+----------------------------------+---------------------+------------------------------+
|            finding_id            |     event_time      |           category           |
+----------------------------------+---------------------+------------------------------+
| 59910148baac6df00abd3037ee1db4c0 | 2026-07-20 02:26:12 | PUBLIC_IP_ADDRESS            |
| d28c94cc9eb2d3d9510e5165b13b438c | 2026-07-20 02:26:12 | COMPUTE_SECURE_BOOT_DISABLED |
| de5893708703f775ce6ff2506478bb95 | 2026-07-20 02:26:12 | FULL_API_ACCESS              |
```

#### 🟢⚠️ Issue solved: $PROJECT_ID should have been used.

```bash
student_04_607ca9b43029@cloudshell:~ (qwiklabs-gcp-01-bf13749f7eb0)$ gcloud scc notifications create export-findings-pubsub \
  --project=$PROJECT \
  --description="Continuous exports of Findings to Pub/Sub and BigQuery" \
  --pubsub-topic=projects/$PROJECT/topics/export-findings-pubsub-topic \
  --filter='state="ACTIVE" AND NOT mute="MUTED"' \
  --log-http
=======================
==== request start ====
uri: https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/student-04-607ca9b43029@qwiklabs.net/allowedLocations
method: GET
== headers start ==
b'X-Goog-User-Project': b'qwiklabs-gcp-01-bf13749f7eb0'
b'authorization': --- Token Redacted ---
b'user-agent': b'google-cloud-sdk gcloud/576.0.0 command/gcloud.scc.notifications.create invocation-id/40ff99ded9f947fa8edbfab3dbe03a76 environment/devshell environment-version/None client-os/LINUX client-os-ver/6.6.143 client-pltf-arch/x86_64 interactive/True from-script/False python/3.14.6 term/tmux-256color  (Linux 6.6.143+)'
== headers end ==
== body start ==

== body end ==
==== request end ====
---- response start ----
status: 404
-- headers start --
Content-Encoding: gzip
Content-Type: application/json; charset=UTF-8
Date: Mon, 20 Jul 2026 01:50:29 GMT
Server: scaffolding on HTTPServer2
Transfer-Encoding: chunked
Vary: Origin, X-Origin, Referer
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
X-XSS-Protection: 0
-- headers end --
-- body start --
{
  "error": {
    "code": 404,
    "message": "Not found; Gaia id not found for email student-04-607ca9b43029@qwiklabs.net",
    "status": "NOT_FOUND"
  }
}

-- body end --
total round trip time (request+response): 0.028 secs
---- response end ----
----------------------
=======================
==== request start ====
uri: https://securitycenter.googleapis.com/v1/projects//notificationConfigs?alt=json&configId=export-findings-pubsub
method: POST
== headers start ==
b'X-Goog-User-Project': b'qwiklabs-gcp-01-bf13749f7eb0'
b'accept': b'application/json'
b'accept-encoding': b'gzip, deflate'
b'authorization': --- Token Redacted ---
b'content-length': b'245'
b'content-type': b'application/json'
b'user-agent': b'google-cloud-sdk gcloud/576.0.0 command/gcloud.scc.notifications.create invocation-id/40ff99ded9f947fa8edbfab3dbe03a76 environment/devshell environment-version/None client-os/LINUX client-os-ver/6.6.143 client-pltf-arch/x86_64 interactive/True from-script/False python/3.14.6 term/tmux-256color  (Linux 6.6.143+)'
b'x-goog-api-client': b'cred-type/mds'
== headers end ==
== body start ==
{"description": "Continuous exports of Findings to Pub/Sub and BigQuery", "name": "export-findings-pubsub", "pubsubTopic": "projects//topics/export-findings-pubsub-topic", "streamingConfig": {"filter": "state=\"ACTIVE\" AND NOT mute=\"MUTED\""}}
== body end ==
==== request end ====
---- response start ----
status: 400
-- headers start --
Content-Encoding: gzip
Content-Type: application/json; charset=UTF-8
Date: Mon, 20 Jul 2026 01:50:29 GMT
Server: ESF
Transfer-Encoding: chunked
Vary: Origin, X-Origin, Referer
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
X-XSS-Protection: 0
-- headers end --
-- body start --
{
  "error": {
    "code": 400,
    "message": "Request contains an invalid argument.",
    "status": "INVALID_ARGUMENT"
  }
}

-- body end --
total round trip time (request+response): 0.048 secs
---- response end ----
----------------------
ERROR: (gcloud.scc.notifications.create) INVALID_ARGUMENT: Request contains an invalid argument.
student_04_607ca9b43029@cloudshell:~ (qwiklabs-gcp-01-bf13749f7eb0)$ 
```

#### 🟢⚠️ Issue solved by GCP.

```bash
student_04_2314b5f4ebaf@cloudshell:~ (qwiklabs-gcp-03-33266879902e)$ gcloud config set project $PROJECT_ID 
Regional Access Boundary HTTP request failed after retries: response_data={'error': {'code': 404, 'message': 'Not found; Gaia id not found for email student-04-2314b5f4ebaf@qwiklabs.net', 'status': 'NOT_FOUND'}}, retryable_error=False
Regional Access Boundary HTTP request failed after retries: response_data={'error': {'code': 404, 'message': 'Not found; Gaia id not found for email student-04-2314b5f4ebaf@qwiklabs.net', 'status': 'NOT_FOUND'}}, retryable_error=False
[environment: untagged] Read more to tag: g.co/cloud/project-env-tag.
Updated property [core/project].
student_04_2314b5f4ebaf@cloudshell:~ (qwiklabs-gcp-03-33266879902e)$ echo $PROJECT_ID
qwiklabs-gcp-03-33266879902e
```

```bash
Regional Access Boundary HTTP request failed after retries:
Gaia id not found for email student-04-2314b5f4ebaf@qwiklabs.net
```

The messages are a Skills Boost/Qwiklabs temporary account identity warning. They are annoying, but in this case they did not stop the command.   

If you want to avoid seeing the warning repeatedly, you can also avoid resetting the account/project unless needed. Cloud Shell already starts with the correct Qwiklabs project and account in most labs.  