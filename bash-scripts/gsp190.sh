#!/bin/bash
## Created by nov05, 2026-06-08

cat << 'EOF'

========================================================
Task 1. View the available permissions for a resource
========================================================

EOF

gcloud iam list-testable-permissions //cloudresourcemanager.googleapis.com/projects/$DEVSHELL_PROJECT_ID

cat << 'EOF'

========================================================
Task 2. Get the role metadata
========================================================

EOF

gcloud iam roles describe roles/viewer
# gcloud iam roles describe roles/editor

cat << 'EOF'

========================================================
Task 3. View the grantable roles on resources
========================================================

EOF

echo -e "\n👉  Grantable roles from Project $DEVSHELL_PROJECT_ID:\n"
gcloud iam list-grantable-roles //cloudresourcemanager.googleapis.com/projects/$DEVSHELL_PROJECT_ID

cat << 'EOF'

========================================================
Task 4. Create a custom role
========================================================

EOF

echo 'title: "Role Editor"
description: "Edit access for App Versions"
stage: "ALPHA"
includedPermissions:
- appengine.versions.create
- appengine.versions.delete' > role-definition.yaml

gcloud iam roles create editor \
    --project $DEVSHELL_PROJECT_ID \
    --file role-definition.yaml

gcloud iam roles create viewer \
    --project $DEVSHELL_PROJECT_ID \
    --title "Role Viewer" \
    --description "Custom role description." \
    --permissions compute.instances.get,compute.instances.list \
    --stage ALPHA

cat << 'EOF'

========================================================
Task 5. List the custom roles
========================================================

EOF

echo -e "\n👉  Custom roles for Project $DEVSHELL_PROJECT_ID:\n"
gcloud iam roles list --project $DEVSHELL_PROJECT_ID

echo -e "\n👉  Predefined roles:\n"
gcloud iam roles list

cat << 'EOF'

========================================================
Task 6. Update an existing custom role
========================================================

EOF

echo 'description: Edit access for App Versions
etag:
includedPermissions:
- appengine.versions.create
- appengine.versions.delete
- storage.buckets.get
- storage.buckets.list
name: projects/'$DEVSHELL_PROJECT_ID'/roles/editor
stage: ALPHA
title: Role Editor' > new-role-definition.yaml

gcloud iam roles update editor \
    --project $DEVSHELL_PROJECT_ID \
    --file new-role-definition.yaml \
    --quiet

gcloud iam roles update viewer \
    --project $DEVSHELL_PROJECT_ID \
    --add-permissions storage.buckets.get,storage.buckets.list

cat << 'EOF'

========================================================
Task 7. Disable a custom role
========================================================

EOF

gcloud iam roles update viewer \
    --project $DEVSHELL_PROJECT_ID \
    --stage DISABLED


cat << 'EOF'

========================================================
Task 8. Delete a custom role
========================================================

EOF

gcloud iam roles delete viewer \
    --project $DEVSHELL_PROJECT_ID

: <<'COMMENT'
After the role has been deleted, existing bindings remain, but are inactive.
The role can be undeleted within 7 days.
After 7 days, the role enters a permanent deletion process that lasts 30 days.
After 37 days, the Role ID is available to be used again.
COMMENT

cat << 'EOF'

========================================================
Task 9. Restore a custom role
========================================================

EOF

gcloud iam roles undelete viewer \
    --project $DEVSHELL_PROJECT_ID

echo -e "\n✅  All done\n"