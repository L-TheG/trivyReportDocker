#!/bin/bash

mkdir ./trivy
curl -LJ -o ./trivy/trivy.tar.gz https://github.com/aquasecurity/trivy/releases/download/v0.36.1/trivy_0.36.1_Linux-64bit.tar.gz
cd trivy
tar -zxvf trivy.tar.gz
./trivy
cd ..

docker-compose up --build
docker-compose rm -f