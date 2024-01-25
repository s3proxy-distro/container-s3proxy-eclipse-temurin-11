FROM maven:3.9.4-eclipse-temurin-11 as builder

RUN mkdir /work
WORKDIR /work

COPY source/ /work

RUN mvn package verify -DskipTests

FROM eclipse-temurin:11.0.22_7-jdk-ubi9-minimal
ARG USER_NAME=s3proxy
ARG USER_ID=10001
ARG GROUP_NAME=s3proxy
ARG GROUP_ID=10001

WORKDIR /opt/s3proxy

USER root
RUN groupadd -g ${GROUP_ID} ${GROUP_NAME} \
    && adduser -l -r -u ${USER_ID} -m -d /home/${USER_NAME} -s /sbin/nologin -c "B2BI user" -g ${GROUP_NAME} ${USER_NAME}
COPY --from=builder \
    /work/target/s3proxy \
    /work/src/main/resources/run-docker-container.sh \
    /opt/s3proxy/

ENV \
    LOG_LEVEL="info" \
    S3PROXY_AUTHORIZATION="aws-v2-or-v4" \
    S3PROXY_ENDPOINT="http://0.0.0.0:80" \
    S3PROXY_IDENTITY="local-identity" \
    S3PROXY_CREDENTIAL="local-credential" \
    S3PROXY_VIRTUALHOST="" \
    S3PROXY_KEYSTORE_PATH="keystore.jks" \
    S3PROXY_KEYSTORE_PASSWORD="password" \
    S3PROXY_CORS_ALLOW_ALL="false" \
    S3PROXY_CORS_ALLOW_ORIGINS="" \
    S3PROXY_CORS_ALLOW_METHODS="" \
    S3PROXY_CORS_ALLOW_HEADERS="" \
    S3PROXY_CORS_ALLOW_CREDENTIAL="" \
    S3PROXY_IGNORE_UNKNOWN_HEADERS="false" \
    S3PROXY_ENCRYPTED_BLOBSTORE="" \
    S3PROXY_ENCRYPTED_BLOBSTORE_PASSWORD="" \
    S3PROXY_ENCRYPTED_BLOBSTORE_SALT="" \
    S3PROXY_READ_ONLY_BLOBSTORE="false" \
    JCLOUDS_PROVIDER="filesystem" \
    JCLOUDS_ENDPOINT="" \
    JCLOUDS_REGION="" \
    JCLOUDS_REGIONS="us-east-1" \
    JCLOUDS_IDENTITY="remote-identity" \
    JCLOUDS_CREDENTIAL="remote-credential" \
    JCLOUDS_KEYSTONE_VERSION="" \
    JCLOUDS_KEYSTONE_SCOPE="" \
    JCLOUDS_KEYSTONE_PROJECT_DOMAIN_NAME="" \
    JCLOUDS_FILESYSTEM_BASEDIR="/data"

USER ${USER_NAME}

EXPOSE 80 443
#checkov:skip=CKV_DOCKER_2: Health check is external 
ENTRYPOINT ["/opt/s3proxy/run-docker-container.sh"]