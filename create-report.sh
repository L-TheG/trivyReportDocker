#!/bin/bash

# define default severity
SEVERITY=CRITICAL

# establish kubeconfig option
KUBECONFIG=""

# reset docker compose 
echo "Resetting docker-compose.yml"
curl -s -LJ -o docker-compose.yml https://raw.githubusercontent.com/L-TheG/trivyReportDocker/main/docker-compose.yml > /dev/null

# Parse Arguments
# --------------------------------
for i in "$@"; do
  case $i in
    -s=*|--severity=*)
      SEVERITY="${i#*=}"
      shift
      ;;
    -in=*|--included-namespaces=*)
      INCLUDED_NAMESPACES="${i#*=}"
      shift
      ;;
    -ex=*|--excluded-namespaces=*)
      EXCLUDED_NAMESPACES="${i#*=}"
      shift
      ;;
    -n|--noscan)
      NOSCAN="true"
      shift
      ;;
    -c=*|--config=*)
      KUBECONFIG="--kubeconfig ${i#*=}"
      echo "looking for kubeconfig at ${i#*=}"
      shift
      ;;
    -*|--*)
      echo "Unknown option $i"
      exit 1
      ;;
    *)
      ;;
  esac
done

# ---------------------------------------------
# Pass all CLI arguments to the actual program

# Add severity value to docker-compose
sed -i "s/\$SEVERITY/$SEVERITY/" docker-compose.yml

# Add exluded namespaces to docker-compose
if [ -n "$EXCLUDED_NAMESPACES" ]
  then 
    sed -i "s/--exclude=\$EXCLUDED_NAMESPACES/--exclude=$EXCLUDED_NAMESPACES/" docker-compose.yml
  else
    sed -i "s/--exclude=\$EXCLUDED_NAMESPACES//" docker-compose.yml
fi

# Add included namespaces to docker-compose
if [ -n "$INCLUDED_NAMESPACES" ]
  then
    sed -i "s/--include=\$INCLUDED_NAMESPACES/--include=$INCLUDED_NAMESPACES/" docker-compose.yml
  else
    sed -i "s/--include=\$INCLUDED_NAMESPACES//" docker-compose.yml
fi

# ------------------------------------
if [ "$NOSCAN" = "true" ]
  then
    echo "Trivy-Scan skipped"
  else
    # Download trivy executable and run it
    echo "Installing Trivy executable"
    mkdir ./trivy
    curl -s -LJ -o ./trivy/trivy.tar.gz https://github.com/aquasecurity/trivy/releases/download/v0.36.1/trivy_0.36.1_Linux-64bit.tar.gz > /dev/null
    cd trivy
    tar -zxf trivy.tar.gz
    cd ..
    ./trivy/trivy k8s $KUBECONFIG --timeout 120m --report=all --format json -o report.json cluster
fi

if sudo -n true 2>/dev/null;
  then 
    # remove old data
    sudo rm -rf ./content
  else
    echo "----------------------------------------- ATTENTION: ------------------------------------------------"
    echo "If you dont run this script as root, delete the ./content folder manually before running this script."
    echo "Or else, the data from the previous report will be included in this report"
    echo "-----------------------------------------------------------------------------------------------------"
fi

# Run the report generator using docker
docker compose build -q
docker-compose run hugo-server
docker-compose rm -f hugo-server