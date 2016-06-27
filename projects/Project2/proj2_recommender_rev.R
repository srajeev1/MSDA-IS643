
## load libraries ####
library(recommenderlab)
library(reshape2)
library(RCurl)
library(ggplot2)




# 1. Load Movie Lens data
dataList<- readData()
# 2. data cleansing and preprocessing --change movieid's to Movie name 
      # ratingDF<- preProcess(dataList$ratingDF, dataList$movieDF)
# 3. create movie rating matrix
movieRatingMat<- createRatingMatrix(dataList$ratingDF)

# 4. Data preparation & Normalization
normmovieRatingMat <- dataprepRatingMatrix(movieRatingMat)

# 5. Split Dataframe
splitData <-splitDF(normmovieRatingMat)
# 6. CBuild recommendation Model
IBCF.model <- createModel(splitData$trainDF,"IBCF")
UBCF.model <- createModel(splitData$trainDF,"UBCF")
  
image(model_details$sim[1:n_items_top, 1:n_items_top],
      main = "Heatmap of the first rows and columns")

#7. Let us get the top 5 recommendations for user 1

userID <- 1
topN <- 5
predict_list <-recommendations(splitData$trainDF, UBCF.model, userID, topN)
predict_list@items[[1]]

subset(dataList$movieDF, movieId %in% predict_list@items[[1]])

# top 5 recommended movies for User 1 is


##1. read movie and ratings data for all users ####
readData <- function(){
  
  ###
  #ratingDF <- read.delim("./data/u.data", header=F)
  #colnames(ratingDF) <- c("userID","movieID","rating", "timestamp")
  ###
  
  ## read movie data  
  moviesurl <- getURL("https://raw.githubusercontent.com/srajeev1/MSDA-IS643/master/projects/project1/ml-latest-small/movies.csv")
  moviesDF <- read.csv(text = moviesurl,header = TRUE)
  head(moviesDF)
  
  ###
  #moviesDF <- read.delim("./data/u.item", sep="|", header=F, stringsAsFactors = FALSE)
  #colnames(moviesDF)[colnames(moviesDF)=="V1"] <- "movieID"
  #colnames(moviesDF)[colnames(moviesDF)=="V2"] <- "name"
  ###
  
  ## read Ratings data
  ratingsurl <- getURL("https://raw.githubusercontent.com/srajeev1/MSDA-IS643/master/projects/project1/ml-latest-small/ratings.csv")
  ratingDF <- read.csv(text = ratingsurl,header = TRUE)
  names(ratingDF)
  
  return(list(ratingDF=ratingDF, movieDF=moviesDF))
  
}

##2. data Cleansing and processing ####
preProcess = function(ratingDF, moviesDF)
{ 
        # ratingDF[,2] <- moviesDF$name[as.numeric(ratingDF[,2])]
        #head(ratingDF)
  
  # remove duplicate entries for any user-movie combination
        #ratingDF <- ratingDF[!duplicated(ratingDF[,1:2]),]
  
  #merge 2 data set to get the movie names in the rating table
  
  ratingDF.moviename = merge(ratingDF, moviesDF, ratingDF=c("movieId"), by.moviesDF=c("movieId"))
  names(ratingDF.moviename)
  
  # we need only userid, moviename and ratings
  ratingDF.moviename  <-ratingDF.moviename[,c("userId","title","rating")] 
  head(ratingDF.moviename)
  
}


visualise <- function(results)
{
  # Draw ROC curve
  plot(results, annotate = 1:3, legend="topright")
  
  # See precision / recall
  plot(results, "prec/rec", annotate=3, legend="topright", xlim=c(0,.22))
}

##3. Create movie ratingMatrix from rating Data and movie data ####
createRatingMatrix <- function(ratingDF)
{
  # converting the ratingData data frame into rating marix
  ratingDF.mat <- dcast( ratingDF, userId ~ movieId, value.var = "rating" , index="userID")
   
  ratingDF.matrix <- as(ratingDF.mat, "matrix")  ## cast data frame as matrix
  #Convert ratingsdf.wide into realRatingMatrix data structure
  #   realRatingMatrix is a recommenderlab sparse-matrix
  ratingDF.ratingMatrix <- as(ratingDF.matrix, "realRatingMatrix")   ## create the realRatingMatrix
  ### setting up the dimnames ###
        #dimnames(ratingDF.ratingMatrix)[[1]] <- row.names(ratingDF)
  
  image(ratingDF.ratingMatrix, main = "Heatmap of the rating matrix")
  image(ratingDF.ratingMatrix[1:10, 1:15], main = "Heatmap of the first 10rows and 15columns")
  return (ratingDF.ratingMatrix)
}

##4. Data preparation ####
#This section will show you how to prepare the data to be used in recommender models. Follow these steps:
  # 1. Select the relevant data.
  #2. Normalize the data. 
dataprepRatingMatrix <- function(ratingDF.ratingMatrix)
{
  #. Users who have rated at least 10 movies
  #. Movies that have been watched at least 20 times
  ratings_movies <- ratingDF.ratingMatrix[rowCounts(ratingDF.ratingMatrix) > 10,
                               colCounts(ratingDF.ratingMatrix) > 20] 
  

  # visualize the top matrix
  min_movies <- quantile(rowCounts(ratings_movies), 0.98)
  min_users <- quantile(colCounts(ratings_movies), 0.98)

  # build the heatmap:
image(ratings_movies[rowCounts(ratings_movies) > min_movies,colCounts(ratings_movies) > min_users], main = "Heatmap of the top users and movies")
average_ratings_per_user <- rowMeans(ratings_movies)

#visualize the distribution:
qplot(average_ratings_per_user) + stat_bin(binwidth = 0.1) +
  ggtitle("Distribution of the average rating per user")


##Normalizing the data
#We can remove this effect by normalizing the data in such a way that the average rating of each user is 0. 
#The prebuilt normalize function does it automatically:
ratings_movies_norm <- normalize(ratings_movies)
#sum(rowMeans(ratings_movies_norm) > 0.00001)

# visualize the normalized matrix
image(ratings_movies_norm[rowCounts(ratings_movies_norm) > min_movies,
                          colCounts(ratings_movies_norm) > min_users], main = "Heatmap of the top users and movies")

return (ratings_movies_norm)
}


##5. Split Dataframe  ####
 
splitDF <- function(normmovieRatingMat)
{
  ## 75% of the sample size
  smp_size <- floor(0.75 * nrow(normmovieRatingMat))
  set.seed(123)
  train_ind <- sample(seq_len(nrow(normmovieRatingMat)), size = smp_size)
  
  train.RatingMat <- normmovieRatingMat[train_ind, ]
  test.RatingMat <- normmovieRatingMat[-train_ind, ]
  
  
  return(list(trainDF=train.RatingMat, testDF=test.RatingMat))
  #IBCF
  #recommender_models <- recommenderRegistry$get_entries(dataType ="realRatingMatrix")
  #recommender_models$IBCF_realRatingMatrix$parameters 
  
#recc_mode.IBCF <- Recommender(data = train.RatingMat, method = "IBCF")
#recc_mode.UBCF <- Recommender(data = train.RatingMat, method = "UBCF")
}

##6. Create Recommender model ####
createModel <-function (movieRatingMat,method)
  {
  
  model <- Recommender(train.RatingMat, method = method)
  names(getModel(model))
  getModel(model)$method
  
  getModel(model)$nn
  
  return (model)
}



##7. get the top 5 recommendations for user 1 ####
recommendations <- function(movieRatingMat, model, userID, n)
{
  
  ### predict top n recommendations for given user
  topN_recommendList <-predict(model,movieRatingMat[userID],n=n) 
  #topN_recommendList <-predict(UBCF.model, train.RatingMat[1],n=5) 
  topN_recommendList@items[[1]]
  return(topN_recommendList)
 
}


