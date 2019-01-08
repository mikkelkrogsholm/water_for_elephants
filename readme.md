# Water for Elephants

### H20 + POSTGRES

![](https://upload.wikimedia.org/wikipedia/commons/thumb/0/07/Elephant_in_water_KalyanVarma.Cat3elephant.jpg/640px-Elephant_in_water_KalyanVarma.Cat3elephant.jpg)


I have combined Rstudio Server, H2O and Postgres, three free and open source tools, to create a data analytics infrastructure that is powerful and capable of doing some nice analytics. H2O of course means “water” and the Postgres logo is an elephant, so I have chosen to call this setup: “Water for Elephants”. 

(Note to self: Since R is also included, maybe it should have been  “WatR for Elephants”)

I also really love docker containers, so everything is of course containerized and the whole thing is orchestrated with a docker-compose file so that it can be brought up with a single command.

With this setup you are able to store and query large data in Postgres and use that data in H2O when you need to run advanced AI analysis. Rstudio Server is used as an IDE to interface with both. 

--

This repo uses dockers with R, H2O and Postgres to show how you can:

* install the h2o package in R from source
* download data from the web
* read it into a postgres database
* read the data from postgres into h2o (water for elephants)
* train a word2vec model in h2o on the data
* use that model to do a prediction

The docker file builds a docker container with H2O and the necesarry driver to connect to Postgres. The docker-compose files launches three containers:

* Rstudio Server with R 3.5.2 (with the Tidyverse installed)
* Postgres 11
* H2O 3.22.1.1

and makes sure they can all connect to eachother.

The rstudio folder holds a tutorial on how to build a word2vec model leveraging this framework.


## This is how you start it

First you download the repository with git clone:

```
git clone https://github.com/mikkelkrogsholm/water_for_elephants
```

And then you bring up the docker-compose file:

```
cd water_for_elephants
docker-compose up -d
```

This creates the infrastructure. When it is up you call:

```
docker-compose ps
```
to see what ports the containers binded to. Like in the example below:

```
   Name                  Command               State            Ports
-------------------------------------------------------------------------------
wfe_h2o       /bin/sh -c java -cp postgr ...   Up      0.0.0.0:32769->54321/tcp
wfe_pg        docker-entrypoint.sh postgres    Up      5432/tcp
wfe_rstudio   /init                            Up      0.0.0.0:32768->8787/tcp
```
In this case you can access Rstudio Server by openening a browser and typing `0.0.0.0:32768` in the address bar. 

The login information for Rstudio is `user` and `password`.

If you know a little about docker and docker-compose then you can change the default settings in the docker-compose file first.

## This is how you use it

In Rstudio there is a project called water_for_elephants. It contains a script called `pg_h20_word2vec.R` that will show you an example of a workflow that utilizes the whole infrastructur. 