## WCL Nuxeo Platform

This directory contains WCL Solution build of Nuxeo Platform

## Installation

Please follow Nuxeo Platform installation guideline to build Nuxeo image.

## Building

Building the WCL Solution Nuxeo Platform with the following steps:

1) Build WCL with the following command

```shell
cd wcl-docker
docker build -f Dockerfile -t wcl/nuxeo .
```

This will create a Docker image named wcl/nuxeo:latest

2) Use docker-compose to execute WCL Nuxeo Platform

```shell
cd wcl-docker
docker-compose up
```
