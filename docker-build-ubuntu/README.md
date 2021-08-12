## WCL Nuxeo Docker Image (without Nuxeo package)

WCL provides a ready to use Docker image with Nuxeo platform.  This folder used to build a Docker image with Operating System + related software.

# Build the Image

It requires to install [Docker](https://doc.docker.com/install/).

```bash
docker build -f Dockerfile -t wcl/nuxeo-ubuntu .
```