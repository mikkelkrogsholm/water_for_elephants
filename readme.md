# Water for Elephants

![](https://upload.wikimedia.org/wikipedia/commons/thumb/0/07/Elephant_in_water_KalyanVarma.Cat3elephant.jpg/640px-Elephant_in_water_KalyanVarma.Cat3elephant.jpg)


![](https://cdn-images-1.medium.com/max/1200/1*vE0y7B8fr-kG2vU2abzEVw.png =x100)

This repo uses dockers with R, H2O and Postgres to show how you can:

* install the h2o package in R from source
* download data from the web
* read it into a postgres database
* read the data from postgres into h2o (water for elephants)
* train a word2vec model in h2o on the data
* use that model to do a prediction

The docker file builds a docker container with H2O and the necesarry driver to connect to Postgres.
The docker-compose files launche three containers: an Rstudio, a Postgres and an H2O docker and makes sure they can all connect to eachother.

The rstudio folder holds a tutorial on how to build a word