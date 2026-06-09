#!/bin/bash

cat << 'EOF'

========================================================
Task 1. Create an API key
========================================================

EOF

gcloud services enable apikeys.googleapis.com
sleep 10
gcloud alpha services api-keys create \
    --display-name="gsp049-api-key" 
export KEY_NAME=$(
    gcloud alpha services api-keys list \
        --format="value(name)" \
        --filter "displayName=gsp049-api-key")
export API_KEY=$(
    gcloud alpha services api-keys get-key-string $KEY_NAME \
        --format="value(keyString)")

cat << 'EOF'

========================================================
Task 2. Translate text
========================================================

EOF

TEXT="My%20name%20is%20Steve"
curl "https://translation.googleapis.com/language/translate/v2?target=es&key=${API_KEY}&q=${TEXT}"

cat << 'EOF'

========================================================
Task 3. Detect the language
========================================================

EOF

TEXT_ONE="Meu%20nome%20é%20Steven"
TEXT_TWO="日本のグーグルのオフィスは、東京の六本木ヒルズにあります"
curl -X POST "https://translation.googleapis.com/language/translate/v2/detect?key=${API_KEY}" \
    -d "q=${TEXT_ONE}" \
    -d "q=${TEXT_TWO}"

echo -e "\n✅  All done\n"