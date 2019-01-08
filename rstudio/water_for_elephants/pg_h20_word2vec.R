# This script shows you how to:

# 0) install the h2o package from source
# 1) download data from the web
# 2) read it into a postgres database
# 3) read the data from postgres into h2o
# 4) train a word2vec model in h2o on the data
# 5) use that model to do a prediction

# The script is an adaptation of this demo:
# A Word2vec demo in R using a Craigslist job titles dataset available at:
# https://github.com/h2oai/h2o-3/blob/master/h2o-r/demos/rdemo.word2vec.craigslistjobtitles.R

################################################################################
###                          0. install h2o package                          ###
################################################################################

# The following two commands remove any previously installed H2O packages for R.
if ("package:h2o" %in% search()) { detach("package:h2o", unload=TRUE) }
if ("h2o" %in% rownames(installed.packages())) { remove.packages("h2o") }

# Next, we download packages that H2O depends on.
pkgs <- c("RCurl","jsonlite")
for (pkg in pkgs) {
  if (! (pkg %in% rownames(installed.packages()))) { install.packages(pkg) }
}

# Now we download, install and initialize the H2O package for R.
install.packages("h2o", type="source", repos="http://h2o-release.s3.amazonaws.com/h2o/rel-xu/1/R")


################################################################################
###                      1. download data from the web                       ###
################################################################################

# First we get a csv file containing job adds from Craigslist

job.titles.url = "https://raw.githubusercontent.com/h2oai/sparkling-water/rel-1.6/examples/smalldata/craigslistJobTitles.csv"

job.titles_local <- readr::read_csv(job.titles.url, col_types = "cc",
                              locale = readr::locale(encoding = "latin1"))

# Inspect the dowloaded data
job.titles_local

################################################################################
###                   2. read it into a postgres database                    ###
################################################################################

# Set connection details 
db_host <- pg_user <- pg_pass <- db_name <- "postgres"
db_port <- 5432

# Connect to the postgres data base in docker
con <- RPostgreSQL::dbConnect(
  drv = DBI::dbDriver("PostgreSQL"),
  host = db_host,
  port = db_port,
  user = pg_user,
  password = pg_pass,
  dbname = db_name
)

# Write the job titles to postgres
DBI::dbWriteTable(con, "jobt_titles", job.titles_local, row.names = FALSE, overwrite = TRUE)

# Inspect the table in postgres
dplyr::tbl(con, "jobt_titles")

################################################################################
###                 3. read the data from postgres into h2o                  ###
################################################################################

# Load the h2o library and connect to the cluster in docker
library(h2o)
h2o.init(ip = "h2o") 

# Connect h2o to postgres and transfer the data fra postgres to h2o
url <- glue::glue("jdbc:postgresql://{db_host}:{db_port}/{db_name}?&useSSL=false")

job.titles <- h2o.import_sql_table(connection_url = url, table = "jobt_titles", 
                               username = pg_user, password = pg_pass)

# Because of the modelling later on we need to change the category column to a 
# factor. We can do this easily from R:

job.titles["category"] <- as.factor(job.titles["category"])

# Inspect the table in h2o
job.titles

################################################################################
###               4. train a word2vec model in h2o on the data               ###
################################################################################

# From here on down it is basically script from the url above

# House keeping: creating necesarry objects and custom function

STOP_WORDS = c("ax","i","you","edu","s","t","m","subject","can","lines","re",
               "what", "there","all","we","one","the","a","an","of","or","in",
               "for","by","on", "but","is","in","a","not","with","as","was","if",
               "they","are","this","and","it","have", "from","at","my","be","by",
               "not","that","to","from","com","org","like","likes","so")

tokenize <- function(sentences, stop.words = STOP_WORDS) {
  tokenized <- h2o.tokenize(sentences, "\\\\W+")
  
  # convert to lower case
  tokenized.lower <- h2o.tolower(tokenized)
  # remove short words (less than 2 characters)
  tokenized.lengths <- h2o.nchar(tokenized.lower)
  tokenized.filtered <- tokenized.lower[is.na(tokenized.lengths) || tokenized.lengths >= 2,]
  # remove words that contain numbers
  tokenized.words <- tokenized.filtered[h2o.grep("[0-9]", tokenized.filtered, invert = TRUE, output.logical = TRUE),]
  
  # remove stop words
  tokenized.words[is.na(tokenized.words) || (! tokenized.words %in% STOP_WORDS),]
}

# Break job titles into sequence of words
words <- tokenize(job.titles$jobtitle)

# Build word2vec model
w2v.model <- h2o.word2vec(words, sent_sample_rate = 0, epochs = 10)

# Sanity check - find synonyms for the word 'teacher'
print(h2o.findSynonyms(w2v.model, "teacher", count = 5))


################################################################################
###                   5. use that model to do a prediction                   ###
################################################################################

# House keeping: creating necesarry custom function
predict <- function(job.title, w2v, gbm) {
  words <- tokenize(as.character(as.h2o(job.title)))
  job.title.vec <- h2o.transform(w2v, words, aggregate_method = "AVERAGE")
  h2o.predict(gbm, job.title.vec)
}

# Calculate a vector for each job title
job.title.vecs <- h2o.transform(w2v.model, words, aggregate_method = "AVERAGE")

# Prepare training & validation data (keep only job titles made of known words)
valid.job.titles <- ! is.na(job.title.vecs$C1)
data <- h2o.cbind(job.titles[valid.job.titles, "category"], job.title.vecs[valid.job.titles, ])
data.split <- h2o.splitFrame(data, ratios = 0.8)

# Build a basic GBM model
gbm.model <- h2o.gbm(x = names(job.title.vecs), y = "category",
                     training_frame = data.split[[1]], validation_frame = data.split[[2]])

# Do some predictions with the new model
# Basically, can we predict the category based on the words in the title
print(predict("school teacher having holidays every month", w2v.model, gbm.model))
print(predict("developer with 3+ Java experience, jumping", w2v.model, gbm.model))
print(predict("Financial accountant CPA preferred", w2v.model, gbm.model))




