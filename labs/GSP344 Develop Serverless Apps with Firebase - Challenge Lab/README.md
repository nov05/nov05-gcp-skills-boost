# 🟢 Develop Serverless Apps with Firebase: Challenge Lab (GSP344)  
https://www.skills.google/games/7172/labs/44422   

```text
Task 1. Create a Firestore database
Task 2. Import the database
Task 3. Create the REST API
Task 4. Configure Firestore API access
Task 5. Deploy the staging frontend
Task 6. Deploy the production frontend
```

* Examples: https://github.com/rosera/pet-theory/lab06  

## 👉 Run the commands in Google Cloud shell

```bash
rm -f gsp344.sh
curl -LO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/main/bash-scripts/gsp344.sh
chmod +x gsp344.sh
./gsp344.sh 2>&1 | tee -a logs.txt
sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g' logs.txt > clean_logs.txt
```

## 👉 Highlights

* Here is [an example](https://support.tools/react-runtime-config-k8s/#react-runtime-configuration-with-kubernetes-and-apache) of configuring React environment variables at runtime using k8s, enabling you to use the same Docker image across dev, staging, and production.

  - Create a config file `config.js`. In your `public/index.html`, inject the config file using a <script> tag:  
    ```html
    <script src="%PUBLIC_URL%/config.js"></script>
    ```   

  - In my `Server-Side Rendering` frontend app, I create variables `year` (frontend app URL path) and `restApiService` (environment variable to store the Firebase REST API service URL) in [`index.js`](https://github.com/nov05/gcp-skills-pet-theory/blob/main/lab06/firebase-frontend/index.js) of the frontend service.
    ```javascript
    app.get('/:year', (req, res) => {
        res.render('index', {
            year: req.params.year,
            restApiService: process.env.REST_API_SERVICE
        });
    });
    ```

    Then in the template file [`view/index.hbs`](https://github.com/nov05/gcp-skills-pet-theory/blob/main/lab06/firebase-frontend/views/index.hbs), inject the variables. 
    ```html
    <html>
	    <head>
            <script>
                window.YEAR = "{{year}}";
                window.REST_API_SERVICE = "{{restApiService}}";
            </script>
            <!-- Link to app.js with defer till HTML render -->
            <script defer src="app.js"></script>
	    </head>
    </html>
    ```

    Finally I retrieve the variables in [`public/app.js`](https://github.com/nov05/gcp-skills-pet-theory/blob/main/lab06/firebase-frontend/public/app.js) at runtime.
    ```javascript
    async function getPageInfo() {
        // Changed by nov05, 2026-05-16
        // const info = await fetchLocalData(REST_API_SERVICE)
        const api = (window.REST_API_SERVICE || "").trim();
        const year = window.YEAR || 2020;
        let url;
        if (api) {
            const base = api.replace(/\/$/, "");
            url = `${base}/${year}`;
        } else {
            url = "data/netflix.json";
        }
        const info = await fetchLocalData(url);
        htmlContent = document.querySelector('#info');
        htmlContent.innerHTML = setTileData(info.content);
    }
    ```