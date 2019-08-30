
<!-- README.md is generated from README.Rmd. Please edit that file -->

# tweetbotr

<!-- badges: start -->

<!-- badges: end -->

<!-- description: start -->

This is package {tweetbotr}: Functions for a Twitter bot.  
Current version is 0.0.0.9000. <!-- description: end -->

## Installation

<!-- install: start -->

The list of dependencies required to install this package is: magrittr.

To install the package, you can run the following script

``` r
# install.packages("remotes")
remotes::install_local(path = "tweetbotr.0.0.0.9000.tar.gz")
```

In case something went wrong, you may want to install dependencies
before using:

``` r
# No Remotes ----
# Attachments ----
to_install <- c("magrittr")
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

This is a basic example which shows you how to solve a common problem:

``` r
library(tweetbotr)
## basic example code
get_and_store(query = "#rspatial", n_tweets = 20)
retweet_and_update(n_tweets = 20, n_limit = 3, sys_sleep = 600, debug = TRUE)
```
