#!/bin/bash

# Automating script for Sonatype Nexus Repository Manager 3 with Nexus Blobstore Google Cloud plugin v1.0
#
#
# ### SUMMARY ###
#
# This script builds a custom Docker image for Nexus Repository Manager with the nexus-blobstore-google-cloud plugin installed. The custom Docker image is based on sonatype/nexus3 Docker image available from Docker Hub.
# Two GCE clusters are created by the script, Staging and Production with Google Kubernetes clusters deployed to them. The Kubernetes clusters are created using the custom docker image.
# The script is designed for usage from GCP command line but could be executed in a BASH shell on any system where the necessary dependencies are installed.
#
#
# ### PRE-REQUISITES ###
#
# The following packages need to be installed: 
#
# - Curl
# - Sed
# - Grep
# - Awk
# - Docker
# - Kubernetes
# - Google Cloud SDK
#
# The following files need to present in the same folder from which the script is executed:
#
# - Dockerfile
# - nexus-gce-disk.yaml		(Kubernetes manifest file)
# - repository.tar		(Maven cache)
# - service-account.json	(GCP service account key file)
#
# If any of the above files does not present, a default version will be dowloaded from the Internet. If they present, they won't be downloaded.
#
# The script is designed for command line usage. NXRM docker image version should be configured in the Dockerfile. The nexus-gce-disk.yaml Kubernetes manifest file will be updated accordingly.
#
# Contact: zsigmond.p.toth@gmail.com



### Cleaning up screen ###

  clear


### Setting general variables ###

  START=`date +%s`
  GREEN='\033[1;32m'
  RED='\033[1;31m'
  NC='\033[0m'


### Testing pre-requisites: Curl, Sed, Grep, Awk, Docker, Kubernetes, Google Cloud SDK ###

  echo -e ${GREEN}
  echo -e "### Testing pre-requisites: Curl, Sed, Grep, Awk, Echo, Docker, Kubernetes, Google Cloud SDK ###"
  echo -e ${NC}

  curl -V > /dev/null 2>&1 || { echo -e ${RED} && echo -e "### Curl is not installed. Please install Curl. Exiting. ###" && echo -e ${NC} && exit 0 ; }

  echo "- Curl: OK"


  sed --version > /dev/null 2>&1 || { echo -e ${RED} && echo -e "### Sed is not installed. Please install Sed. Exiting. ###" && echo -e ${NC} && exit 0 ; }

  echo "- Sed: OK"


  grep -V > /dev/null 2>&1 || { echo -e ${RED} && echo -e "### Grep is not installed. Please install Grep. Exiting. ###" && echo -e ${NC} && exit 0 ; }

  echo "- Grep: OK"


  awk -V > /dev/null 2>&1 || { echo -e ${RED} && echo -e "### Awk is not installed. Please install Awk. Exiting. ###" && echo -e ${NC} && exit 0 ; }

  echo "- Awk: OK"


  docker -v > /dev/null 2>&1 || { echo -e ${RED} && echo -e "### Docker is not installed. Please install Docker. Exiting. ###" && echo -e ${NC} && exit 0 ; }

  echo "- Docker: OK"


  kubectl > /dev/null 2>&1 || { echo -e ${RED} && echo -e "### Kubernetes is not installed. Please install Kubernetes. Exiting. ###" && echo -e ${NC} && exit 0 ; }

  echo "- Kubernetes: OK"


  gcloud version > /dev/null 2>&1 || { echo -e ${RED} && echo -e "### Google Cloud SDK is not installed. Please install Google Cloud SDK. Exiting. ###" && echo -e ${NC} && exit 0 ; }

  echo "- Google Cloud SDK: OK"
 
  echo -e ${GREEN}
  echo -e "### Pre-requisites installed ###"
  echo -e ${NC}


### Downloading banner if it does not exists ###

  if ! [ -f banner.txt ]; then
    curl -s -o banner.txt https://storage.googleapis.com/aliz-nexus/banner.txt
  fi


### Downloading Dockerfile if it does not exist ###

  if ! [ -f Dockerfile ]; then
    curl -f -s -o Dockerfile https://raw.githubusercontent.com/zptoth-aliz/nexus/master/1_container/Dockerfile
  fi

  if [ $? -ne 0 ]; then
    echo -e ${RED}
    echo -e "### Dockerfile does not exist and cannot be downloaded. Exiting. ###"
    echo -e ${NC}

    exit 0
  fi


### Downloading Kubernetes manifest file if it does not exist ###

  if ! [ -f nexus-gce-disk.yaml ]; then
    curl -f -s -o nexus-gce-disk.yaml https://raw.githubusercontent.com/zptoth-aliz/nexus/master/2_kubernetes/nexus-gce-disk.yaml
  fi

  if [ $? -ne 0 ]; then
    echo -e ${RED}
    echo -e "### Kubernetes manifest file does not exist and cannot be downloaded. Exiting. ###"
    echo -e ${NC}

    exit 0
  fi


### Downloading Service account key file if it does not exist ###

  if ! [ -f gcp-service-account.json ]; then
    curl -f -s -o gcp-service-account.json https://storage.googleapis.com/aliz-nexus/gcp-service-account.json
  fi

  if [ $? -ne 0 ]; then
    echo -e ${RED}
    echo -e "### Service account key file does not exist and cannot be downloaded. Exiting. ###"
    echo -e ${NC}

    exit 0
  fi



### Setting variables for deployment ###

  PROJECT=aliz-nexus
  TAG=`cat Dockerfile | sed -n 's/.*ARG TAGVERSION=//p'`
  IMAGE=nexus3-custom
  GCRIMAGE=gcr.io/$PROJECT/$IMAGE:$TAG
  SCLUSTER=nexus-cluster-stage
  PCLUSTER=nexus-cluster-prod
  REGION=europe-west4
  ZONE=europe-west4-a
  STAGING="gke_${PROJECT}_${ZONE}_${SCLUSTER}"
  PRODUCTION="gke_${PROJECT}_${ZONE}_${PCLUSTER}"


  if [[ $TAG == "" ]]; then
    echo -e ${RED}
    echo -e "### TAG variable could not be set. Exiting. ###"
    echo -e ${NC}

    exit 0
  fi


### Updating image info in Kubernetes manifest file ###

  sed -i 's@gcr.*@'"$GCRIMAGE"'@' nexus-gce-disk.yaml

  if [ $? -ne 0 ]; then
    echo -e ${RED}
    echo -e "### Kubernetes manifest file file could not be updated. Exiting. ###"
    echo -e ${NC}

    exit 0
  fi


### Displaying banner ###

  cat banner.txt


### Displaying summary info ###

  echo
  echo "#####################################################"
  echo
  echo - GCP project id: $PROJECT
  echo - Region: $REGION
  echo - Zone: $ZONE
  echo - Staging cluster: $SCLUSTER
  echo - Production cluster: $PCLUSTER
  echo - Docker image name and tag: $IMAGE:$TAG
  echo
  echo "#####################################################"
  echo


### Pausing for 5 secs to display summary info ### 

  sleep 5


### Setting GCP Project ###

  echo -e ${GREEN}
  echo -e "### Setting GCP Project ###"
  echo -e ${NC}

  gcloud config set project $PROJECT

  if [ $? -ne 0 ]; then
    echo -e ${RED}
    echo -e "### Could not set GCP Project. Exiting. ###"
    echo -e ${NC}

    exit 0
  fi


### Authenticating with GCP Service Account ###

  echo -e ${GREEN}
  echo -e "### Authenticating with GCP Service Account ###"
  echo -e ${NC}

  gcloud auth activate-service-account --key-file=gcp-service-account.json

  if [ $? -ne 0 ]; then
    echo -e ${RED}
    echo -e "### Could not authenticate with service account. Exiting. ###"
    echo -e ${NC}

    exit 0
  fi


### Authenticating to Google Container Registry ###

  echo -e ${GREEN}
  echo -e "### Authenticating to Google Container Registry ###"
  echo -e ${NC}

  gcloud auth configure-docker --quiet

  if [ $? -ne 0 ]; then
    echo -e ${RED}
    echo -e "### Could not authenticate to Google Container Registry Exiting. ###"
    echo -e ${NC}

    exit 0
  fi


### Enabling Kubernetes Engine API if not enabled ###

  if ! gcloud services list --enabled |grep "container.googleapis.com" > /dev/null 2>&1
    then
      echo -e ${GREEN}
      echo -e "### Enabling Kubernetes Engine API ###"
      echo -e ${NC}

      gcloud services enable container.googleapis.com

      if [ $? -ne 0 ]; then
        echo -e ${RED}
        echo -e "### Kubernetes Engine API could not be enabled. Exiting. ###"
        echo -e ${NC}

        exit 0
      fi

  fi


### Enabling Container Registry API if not enabled ###

  if ! gcloud services list --enabled |grep "containerregistry.googleapis.com" > /dev/null 2>&1
    then
      echo -e ${GREEN}
      echo -e "### Enabling Container Registry API ###"
      echo -e ${NC}

      gcloud services enable cntainerregistry.googleapis.com

      if [ $? -ne 0 ]; then
        echo -e ${RED}
        echo -e "### Container Registry API could not be enabled. Exiting. ###"
        echo -e ${NC}

        exit 0
      fi

  fi


### Enabling Cloud Datastore API if not enabled ###

  if ! gcloud services list --enabled |grep "datastore.googleapis.com" > /dev/null 2>&1
    then
      echo -e ${GREEN}
      echo -e "### Enabling Cloud Datastore API ###"
      echo -e ${NC}

      gcloud services enable datastore.googleapis.com

      if [ $? -ne 0 ]; then
        echo -e ${RED}
        echo -e "### Cloud Datastore API could not be enabled. Exiting. ###"
        echo -e ${NC}

        exit 0
      fi

  fi


### Downloading data for local Maven cache ###

  if ! [ -f repository.tar ]; then
    echo -e ${GREEN}
    echo -e "### Downloading for local Maven cache ###"
    echo -e ${NC}

    curl -o repository.tar https://storage.googleapis.com/aliz-nexus/repository.tar 
  fi


### Building Docker image ###

  echo -e ${GREEN}
  echo -e "### Building Docker image ###"
  echo -e ${NC}

  docker build -t $GCRIMAGE -f Dockerfile .

  if [ $? -ne 0 ]; then
    echo -e ${RED}
    echo -e "### Docker image could not be built. Exiting. ###"
    echo -e ${NC}

    exit 0
  fi


### Pushing container image to Google Container Registry ###

  echo -e ${GREEN}
  echo -e "### Pushing container image to Google Container Registry ###"
  echo -e ${NC}

  docker push $GCRIMAGE

  if [ $? -ne 0 ]; then
    echo -e ${RED}
    echo -e "### Docker image could not be pushed to Google Container Registry. Exiting. ###"
    echo -e ${NC}

    exit 0
  fi


### Creating staging cluster if it does not exist ###

  gcloud beta container clusters describe --zone $ZONE $SCLUSTER > /dev/null 2>&1 || { echo -e ${GREEN} && echo -e "### Creating staging cluster ###" && echo -e ${NC} && \

    gcloud beta container \
	--project "$PROJECT" \
	clusters create "$SCLUSTER" \
	--zone "$ZONE" \
	--username "admin" \
	--cluster-version "1.11.6-gke.3" \
	--machine-type "n1-standard-2" \
	--image-type "COS" \
	--disk-type "pd-standard" \
	--disk-size "100" \
	--scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" \
	--num-nodes "1" \
	--enable-cloud-logging \
	--enable-cloud-monitoring \
	--no-enable-ip-alias \
	--network "projects/$PROJECT/global/networks/default" \
	--subnetwork "projects/$PROJECT/regions/$REGION/subnetworks/default" \
	--addons HorizontalPodAutoscaling,HttpLoadBalancing \
	--enable-autoupgrade \
        --enable-autorepair \
   ;
  }

  if [ $? -ne 0 ]; then
    echo -e ${RED}
    echo -e "### Staging cluster could not be created. Exiting. ###"
    echo -e ${NC}

    exit 0
  fi


### Fetching staging cluster endpoint and auth data ###

  echo -e ${GREEN}
  echo -e "### Fetching staging cluster endpoint and auth data ###"
  echo -e ${NC}

  gcloud beta container clusters get-credentials --zone=$ZONE --project=$PROJECT $SCLUSTER

  if [ $? -ne 0 ]; then
    echo -e ${RED}
    echo -e "###  Could not fetch staging cluster endpoint and auth data. Exiting. ###"
    echo -e ${NC}

    exit 0
  fi


### Creating production cluster if it does not exist ###

  gcloud beta container clusters describe --zone $ZONE $PCLUSTER > /dev/null 2>&1 || { echo -e ${GREEN} && echo -e "### Creating production cluster ###" && echo -e ${NC} && \

    gcloud beta container \
	--project "$PROJECT" \
	clusters create "$PCLUSTER" \
	--zone "$ZONE" \
	--username "admin" \
	--cluster-version "1.11.6-gke.3" \
	--machine-type "n1-standard-2" \
	--image-type "COS" \
	--disk-type "pd-standard" \
	--disk-size "100" \
	--scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" \
	--num-nodes "1" \
	--enable-cloud-logging \
	--enable-cloud-monitoring \
	--no-enable-ip-alias \
	--network "projects/$PROJECT/global/networks/default" \
	--subnetwork "projects/$PROJECT/regions/$REGION/subnetworks/default" \
	--addons HorizontalPodAutoscaling,HttpLoadBalancing \
	--enable-autoupgrade \
        --enable-autorepair \
   ;
  }

  if [ $? -ne 0 ]; then
    echo -e ${RED}
    echo -e "### Production cluster could not be created. Exiting. ###"
    echo -e ${NC}

    exit 0
  fi


### Fetching production cluster endpoint and auth data ###

  echo -e ${GREEN}
  echo -e "### Fetching production cluster endpoint and auth data ###"
  echo -e ${NC}

  gcloud beta container clusters get-credentials --zone=$ZONE --project=$PROJECT $PCLUSTER

  if [ $? -ne 0 ]; then
    echo -e ${RED}
    echo -e "###  Could not fetch production cluster endpoint and auth data. Exiting. ###"
    echo -e ${NC}

    exit 0
  fi


### Deploying Kubernetes to staging cluster ###

  echo -e ${GREEN}
  echo -e "### Deploying Kubernetes to staging cluster ###"
  echo -e ${NC}

  kubectl apply -f nexus-gce-disk.yaml --cluster=$STAGING

  if [ $? -ne 0 ]; then
    echo -e ${RED}
    echo -e "###  Could not deploy Kubernetes to staging cluster. Exiting. ###"
    echo -e ${NC}

    exit 0
  fi


### Waiting for staging cluster LoadBalancer to come up ###

  echo -e ${GREEN}
  echo -e "### Readyness probe - Waiting for staging cluster LoadBalancer to come up ###"
  echo -e ${NC}

  while [ "$SLBIP" = "" ]
  do
    SLBIP=`kubectl describe service nexus-service --cluster=$STAGING | grep "LoadBalancer Ingress" | awk ' {print $3} '`
    sleep 3
    echo -n "."
  done

  echo "OK"


### Checking staging cluster LoadBalancer port ###

  SLBPORT=`kubectl describe service nexus-service --cluster=$STAGING | grep -m 1 "Port" | awk ' {print $3} '`


### Displaying staging deployment summary ###

  echo -e ${GREEN}
  echo -e "### Readyness probe - Waiting for Nexus Repository Manager to come up ###"
  echo -e ${NC}

  until curl -s $SLBIP -o /dev/null
  do
    sleep 3
    echo -n "."
  done

  echo "OK"

  echo -e ${GREEN}
  echo -e "################################# STAGING BUILD SUMMARY ##################################"
  echo -e 
  echo -e "Your Nexus Repository Manager is available at: http://$SLBIP at port: $SLBPORT"
  echo -e 
  echo -e "Version: $TAG"
  echo -e 
  echo -e "Username: admin"
  echo -e 
  echo -e "Password: admin123"
  echo -e 
  echo -e "Absolute path to Google Application Credentials JSON file: /opt/gce-credentials.json"
  echo -e 
  echo -e "##########################################################################################"
  echo -e ${NC}

  echo "Deploy to production?"
  echo 

  select yn in "Yes" "No"; do
      case $yn in
          Yes ) 


### Deploying Kubernetes to production cluster ###

  echo -e ${GREEN}
  echo -e "### Deploying Kubernetes to production cluster ###"
  echo -e ${NC}

  kubectl apply -f nexus-gce-disk.yaml --cluster=$PRODUCTION

  if [ $? -ne 0 ]; then
    echo -e ${RED}
    echo -e "###  Could not deploy Kubernetes to production cluster. Exiting. ###"
    echo -e ${NC}

    exit 0
  fi


### Waiting for production cluster LoadBalancer to come up ###

  echo -e ${GREEN}
  echo -e "### Readyness probe - Waiting for production cluster LoadBalancer to come up ###"
  echo -e ${NC}

  while [ "$PLBIP" = "" ]
  do
    PLBIP=`kubectl describe service nexus-service --cluster=$PRODUCTION | grep "LoadBalancer Ingress" | awk ' {print $3} '`
    sleep 3
    echo -n "."
  done

  echo "OK"


### Checking production cluster LoadBalancer port ###

  PLBPORT=`kubectl describe service nexus-service --cluster=$PRODUCTION | grep -m 1 "Port" | awk ' {print $3} '`


### Displaying production deployment summary ###

  echo -e ${GREEN}
  echo -e "### Readyness probe - Waiting for Nexus Repository Manager to come up ###"
  echo -e ${NC}

  until curl -s $PLBIP -o /dev/null
  do
    sleep 3
    echo -n "."
  done

  echo "OK"

  echo -e ${GREEN}
  echo -e "############################### PRODUCTION BUILD SUMMARY #################################"
  echo -e 
  echo -e "Your Nexus Repository Manager is available at: http://$PLBIP at port: $PLBPORT"
  echo -e 
  echo -e "Version: $TAG"
  echo -e 
  echo -e "Username: admin"
  echo -e 
  echo -e "Password: admin123"
  echo -e 
  echo -e "Absolute path to Google Application Credentials JSON file: /opt/gce-credentials.json"
  echo -e 
  echo -e "##########################################################################################"
  echo -e ${NC}

  END=`date +%s`

  echo "Automating script completed in $((END-START)) secs."
  echo

  break;;

          No ) 


  END=`date +%s`

  echo "Automating script completed in $((END-START)) secs."
  echo

  exit;;

      esac
  done
