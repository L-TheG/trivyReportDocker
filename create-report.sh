#!/bin/bash

# define default severity
SEVERITY=CRITICAL
NOSCAN=false
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
      NOSCAN=true
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
if ["$NOSCAN" = true]
  then
    # Download trivy executable and run it
    echo "Installing Trivy executable"
    mkdir ./trivy
    curl -LJ -o ./trivy/trivy.tar.gz https://github.com/aquasecurity/trivy/releases/download/v0.36.1/trivy_0.36.1_Linux-64bit.tar.gz
    cd trivy
    tar -zxf trivy.tar.gz
    cd ..
    ./trivy/trivy k8s --timeout 120m --report=all --format json -o report.json cluster
    rm -rf /trivy
  else
    echo "Trivy-Scan skipped"
fi

# Run the report generator using docker
docker compose build -q
docker-compose run hugo-server
docker-compose rm -f hugo-server

# ------------------------------------
# Restore docker-compose file to original state
echo "Resetting docker-compose file"
sed -i "s/$SEVERITY/\$SEVERITY/" docker-compose.yml

if [ -n "$EXCLUDED_NAMESPACES" ]
  then
    # if params are set, replace  current params with placeholder
    sed -i "s/--exclude=$EXCLUDED_NAMESPACES/--exclude=\$EXCLUDED_NAMESPACES/" docker-compose.yml
  else
    # if no parameters set, append whole setup
    sed -i "/node .\/build\/index.js --outDir=\//s/$/--exclude=\$EXCLUDED_NAMESPACES/" docker-compose.yml
fi

if [ -n "$INCLUDED_NAMESPACES" ]
  then
    # if params are set, replace  current params with placeholder
    sed -i "s/--include=$INCLUDED_NAMESPACES/--include=\$INCLUDED_NAMESPACES/" docker-compose.yml
  else
    # if no parameters set, append whole setup
    sed -i "/node .\/build\/index.js --outDir=\//s/$/--include=\$INCLUDED_NAMESPACES/" docker-compose.yml
fi
