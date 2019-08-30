
<!-- README.md is generated from README.Rmd. Please edit that file -->

# tweetrbot

<!-- badges: start -->

<!-- badges: end -->

<!-- description: start -->

This is package {tweetrbot}: Functions for a Twitter bot.  
Current version is 0.0.0.9000. <!-- description: end -->

## Installation

<!-- install: start -->

The list of dependencies required to install this package is: dplyr,
knitr, magrittr, rmarkdown, rtweet.

To install the package, you can run the following script

``` r
# install.packages("remotes")
remotes::install_github(repo = "statnmap/tweetrbot")
```

In case something went wrong, you may want to install dependencies
before using:

``` r
# No Remotes ----
# Attachments ----
to_install <- c("dplyr", "magrittr", "rtweet")
  for (i in to_install) {
    message(paste("looking for ", i))
    if (!requireNamespace(i)) {
      message(paste("     installing", i))
      install.packages(i)
    }
  }
```

<!-- install: end -->

## Example

This package is presented in a blog post on <https://statnmap.com/>

This is set for a bot. This means that every tweets retrieved from
`get_and_store()` will be retweet using `retweet_and_update()` using a
loop, with 1 tweet every 600 seconds here. Also set to `debug=TRUE` like
here to avoid really tweeting on Twitter if you want to make some tests.

``` r
library(tweetrbot)
## Retrieve tweets, store on the drive
get_and_store(query = "#rspatial", n_tweets = 20, dir = ".")
## Tweet regularly and update the table stored on the drive
retweet_and_update(dir = ".", n_tweets = 20, n_limit = 3, sys_sleep = 600, debug = TRUE)
```
