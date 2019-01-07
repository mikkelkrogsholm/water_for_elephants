# Get the base image
FROM ubuntu:18.04

# Install java - openJDK - must be 8
RUN apt update && apt install -y openjdk-8-jdk

# Install h2o ubuntu dependencies
RUN apt-get update && \
  apt-get install -y --no-install-recommends wget unzip

## Get the h2o files
RUN wget http://h2o-release.s3.amazonaws.com/h2o/rel-xu/1/h2o-3.22.1.1.zip && \
  unzip h2o-3.22.1.1.zip && \
  rm -f h2o-3.22.1.1.zip

## Change the directory
WORKDIR h2o-3.22.1.1

# Get the postgres JDBC driver
RUN wget https://jdbc.postgresql.org/download/postgresql-42.2.5.jar

# Expose the port
EXPOSE 54321

# Start h2o
CMD java -cp postgresql-42.2.5.jar:h2o.jar water.H2OApp
