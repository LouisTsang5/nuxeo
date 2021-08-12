# WCL Nuxeo Docker Image

WCL provides a ready to use Docker image with Nuxeo platform.  This folder used to build a WCL Edition of Nuxeo Docker image.

## Build the Image

- It requires to install [Docker](https://doc.docker.com/install/).
- It requires Docker image wcl/nuxeo-ubuntu:latest.

```shell
docker build -f Dockerfile -t wcl/nuxeo .
```

## Run the image with MySQL and ElasticSearch
```bash
docker-compose up
```