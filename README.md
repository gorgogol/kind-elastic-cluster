# Kind Elastic

Scripts that help spin up an Elastic cluster fast, with minimum effort.

## Prerequisites

To run these scripts, you need the following:

- Docker
- Kind (Kubernetes in Docker)
- Kubernetes CLI (kubectl)
- PowerShell (for running .ps1 script)

## Scripts

1. **create-kind-cluster.bat** - This script creates a Kubernetes Kind cluster using the configuration specified in the `kind-config.yaml` file.

2. **create-elast-cluster.ps1** - This PowerShell script deploys an Elastic cluster on the Kubernetes cluster created by the `create-kind-cluster.bat` script. The Elastic cluster includes Kibana and a Fleet server.

## How to use

1. Open your terminal.

2. Clone this repository:

    ```
    git clone https://github.com/yourusername/reponame.git
    cd reponame
    ```

3. Run the `create-kind-cluster.bat` script:

    ```
    create-kind-cluster.bat
    ```

  
4. After the Kind cluster is ready, run the `create-elast-cluster.ps1` in a PowerShell terminal:

    ```
    .\create-elast-cluster.ps1
    ```

    Output will include the credentials for accessing elasticsearch and sKibana.
 
 
5. After the Elastic cluster is ready, you can access Kibana at `http://localhost:5601`.

