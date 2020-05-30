
<!-- README.md is generated from README.Rmd. Please edit that file -->

# tweetrbot

<!-- badges: start -->

[![R build
status](https://github.com/statnmap/tweetrbot/workflows/R-CMD-check/badge.svg)](https://github.com/statnmap/tweetrbot/actions)
<!-- badges: end -->

<!-- description: start -->

This is package {tweetrbot}: Functions for a Twitter bot.  
Current version is 0.0.1 <!-- description: end -->

## Installation

<!-- install: start -->

The list of dependencies required to install this package is: {dplyr},
{knitr}, {magrittr}, {rmarkdown}, {rtweet}.

To install the package, you can run the following script

``` r
# install.packages("remotes")
remotes::install_github(repo = "statnmap/tweetrbot")
```

## Example

<img src="reference/figures/fig_tweetrbot_with_func.png" width="60%" style="display: block; margin: auto;" />

``` r
library(tweetrbot)
```

This package is presented in a blog post on
<https://statnmap.com/2019-08-30-create-a-twitter-bot-on-a-raspberry-pi-3-using-r>

### Run the scripts to retweet a specific hashtag

This is set for a bot. This means that every tweets retrieved from
`get_and_store()` will be retweeted using `retweet_and_update()` using a
loop, with 1 tweet every 600 seconds here. Set to `debug=TRUE` to avoid
really tweeting on Twitter if you want to make some tests.

``` r
## Retrieve tweets, store on the drive
get_and_store(query = "#rspatial", n_tweets = 20, dir = ".")
## Tweet regularly and update the table stored on the drive
retweet_and_update(dir = ".", n_tweets = 20, n_limit = 3, sys_sleep = 600, debug = TRUE)
```

### Run the script to retrieve your user information

``` r
get_account_info(user = "talk_rspatial")
```

### Post the most retweeted tweet of the month

Get the database gathered with `get_and_store()` and tweet the top of
the month using `top_tweets()`.

``` r
rds_file <- "complete_tweets_rspatial.rds"
all_tweets <- readRDS(rds_file)
# filter on last month
last_month_tweets <- all_tweets %>% filter_month(the_month = 4)
# update last month
last_month_updated <- update_data(
  path = rds_file, 
  statuses = last_month_tweets$status_id)
# Get stats of last month tweets
top_tweets(all_tweets = last_month_updated, post_tweet = TRUE, top_number = 5)
```
