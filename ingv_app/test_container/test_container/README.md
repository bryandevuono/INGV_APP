# Mock Environment for INGV Data Services

## Overview

This mock environment simulates the behavior of various INGV data services, including:
-   Legacy TSD System (Filtered API)
-   Seismological FDSNWS (Dataselect & Station)
-   Video Binary (AVI)
-   New TSD System (REST API)
-   Fallback Route
-   Mock MySQL Database

## Running the Mock Environment
To start the mock environment, run the following command in the terminal:

```bash
docker-compose up -d
```

This will start both the Nginx server (serving the mock API responses) and the MySQL database container.

In the Nginx container, the mock API responses are served from the `/mock-data` directory, which is mounted from the `mock-env` folder in the project.

There is a `.http` file that contains example HTTP requests for testing the various endpoints. You can use this file with an HTTP client extension (like REST Client in VSCode) to easily send requests to the mock API.

## Accessing the Mock Database

You can connect to the mock MySQL database using any standard database client, such as DBeaver or DataGrip.

Use the following connection details:

-   **Host**: `localhost`
-   **Port**: `3306`
-   **Database**: `ingv_mock`
-   **Username**: `mock_user`
-   **Password**: `mock_password`
