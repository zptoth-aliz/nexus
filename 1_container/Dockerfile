# Sonatype Nexus Repository Manager 3 with Nexus Blobstore Google Cloud plugin v1.0

### Setting version tag ###

ARG TAGVERSION=latest



### Defining source image ###

FROM sonatype/nexus3:$TAGVERSION



### Setting maintainer label ###

LABEL maintainer="zsigmond.p.toth@gmail.com"



### Switching user to root ###

USER root



#################################################

RUN mkdir /root/.m2 

ADD repository.tar /root/.m2/

#################################################




### Installing Google Cloud SDK and git ###

# RUN cd /etc/yum.repos.d/
# RUN echo "[google-cloud-sdk]" >> google-cloud-sdk.repo
# RUN echo "name=Google Cloud SDK" >> google-cloud-sdk.repo
# RUN echo "baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el7-x86_64" >> google-cloud-sdk.repo
# RUN echo "enabled=1" >> google-cloud-sdk.repo
# RUN echo "gpgcheck=1" >> google-cloud-sdk.repo
# RUN echo "repo_gpgcheck=1" >> google-cloud-sdk.repo
# RUN echo "gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg" >> google-cloud-sdk.repo
# RUN echo "       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg" >> google-cloud-sdk.repo
# RUN yum install -y google-cloud-sdk
# RUN yum install -y git

# Executing chanied up

RUN cd /etc/yum.repos.d/ && echo "[google-cloud-sdk]" >> google-cloud-sdk.repo && echo "name=Google Cloud SDK" >> google-cloud-sdk.repo && echo "baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el7-x86_64" >> google-cloud-sdk.repo && echo "enabled=1" >> google-cloud-sdk.repo && echo "gpgcheck=1" >> google-cloud-sdk.repo && echo "repo_gpgcheck=1" >> google-cloud-sdk.repo && echo "gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg" >> google-cloud-sdk.repo && echo "       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg" >> google-cloud-sdk.repo && yum install -y google-cloud-sdk git



### Downloading & Installing Maven 3.6.0 ###

# RUN cd /opt/
# RUN curl https://www-eu.apache.org/dist/maven/maven-3/3.6.0/binaries/apache-maven-3.6.0-bin.tar.gz | tar xvz
# RUN ln -s apache-maven-3.6.0 maven

# Executing chained up

RUN cd /opt/ && curl https://www-eu.apache.org/dist/maven/maven-3/3.6.0/binaries/apache-maven-3.6.0-bin.tar.gz | tar xvz && ln -s apache-maven-3.6.0 maven



### Downloading nexus-blobstore-google-cloud plugin & Setting environment variable GOOGLE_APPLICATION_CREDENTIALS & Downloading service account authentication key & Copying key to plugin source & Activating Service Account ###

# RUN git clone https://github.com/sonatype-nexus-community/nexus-blobstore-google-cloud.git /usr/src/nexus-blobstore-google-cloud
# RUN export GOOGLE_APPLICATION_CREDENTIALS=/opt/gce-credentials.json
# RUN curl https://storage.googleapis.com/aliz-nexus/gce-credentials.json -o $GOOGLE_APPLICATION_CREDENTIALS
# RUN cp $GOOGLE_APPLICATION_CREDENTIALS /usr/src/nexus-blobstore-google-cloud/src/test/resources/
# RUN gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS

#  Executing chained up

RUN git clone https://github.com/sonatype-nexus-community/nexus-blobstore-google-cloud.git /usr/src/nexus-blobstore-google-cloud && export GOOGLE_APPLICATION_CREDENTIALS=/opt/gce-credentials.json && curl https://storage.googleapis.com/aliz-nexus/gce-credentials.json -o $GOOGLE_APPLICATION_CREDENTIALS && cp $GOOGLE_APPLICATION_CREDENTIALS /usr/src/nexus-blobstore-google-cloud/src/test/resources/ && gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS



### Compiling & Installing nexus-blobstore-google-cloud plugin & Cleaning up ###

# RUN cd /usr/src/nexus-blobstore-google-cloud/ 
# RUN /opt/maven/bin/mvn -e clean install 
# RUN sh /usr/src/nexus-blobstore-google-cloud/install-plugin.sh /opt/sonatype/nexus
# RUN rm -rfv /root/.m2
# RUN rm -rfv /usr/src/nexus-blobstore-google-cloud
# RUN rm -rfv /opt/apache-maven-3.6.0

# Executing chained up

RUN cd /usr/src/nexus-blobstore-google-cloud/ && /opt/maven/bin/mvn -e clean install && sh /usr/src/nexus-blobstore-google-cloud/install-plugin.sh /opt/sonatype/nexus && rm -rfv /root/.m2 && rm -rfv /usr/src/nexus-blobstore-google-cloud && rm -rfv /opt/apache-maven-3.6.0



### Other action ###

ENV GOOGLE_APPLICATION_CREDENTIALS=/opt/gce-credentials.json

EXPOSE 8081/tcp
