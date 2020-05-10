#' Create a tweet for top retweets
#'
#' @param all_tweets Table of tweets to explore
#' @param save_dir Path where to save images that will be tweet
#' @param post_tweet Logical. Whether to really tweet the content
#' @param top_number Numeric. Number of best retweeted tweets to show on the graph
#' @param hashtag Character. Which Twitter hashtag is followed
#'
#' @export
#'
#' @importFrom lubridate month today ymd_hms as_date
#' @importFrom dplyr filter mutate top_n select arrange count
#' @importFrom glue glue
#' @importFrom ggplot2 ggplot aes geom_col coord_flip labs theme_classic ggsave coord_cartesian
#' @importFrom rtweet post_tweet
#' @importFrom stats reorder

top_tweets <- function(all_tweets, save_dir = tempdir(), post_tweet = TRUE,
                       top_number = 5, hashtag = "rspatial") {

  # Filter for the last month
  current_month <- month(today())

  last_month_tweets <- all_tweets %>%
    mutate(created_at = ymd_hms(created_at)) %>%
    filter(month(created_at) == ifelse(current_month == 1, 12, current_month - 1) &
             is_retweet == FALSE)

  # The most retweet
  most_tweet <- last_month_tweets %>%
    top_n(1, retweet_count) %>%
    mutate(tweet_url =
             sprintf("https://twitter.com/%s/status/%s",
                     screen_name, status_id)) %>%
    select(tweet_url, screen_name)

  text <- glue("The {ifelse(length(most_tweet$tweet_url) > 1, paste(length(most_tweet$tweet_url), 'most'), 'most')} retweeted #{hashtag} of last month {ifelse(length(most_tweet$tweet_url) > 1, paste('are', paste(paste(most_tweet$tweet_url, 'by', paste0('@', most_tweet$screen_name)), collapse = ', ')), paste('is', most_tweet$tweet_url, 'by', paste0('@', most_tweet$screen_name)))}.")

  g1 <- last_month_tweets %>%
    top_n(top_number, retweet_count) %>%
    arrange(desc(retweet_count)) %>%
    mutate(name_tweet = paste(1:n(), screen_name, sep = " - ")) %>%
    ggplot() +
    aes(x = reorder(name_tweet, retweet_count), y = retweet_count) +
    geom_col(fill = "#1e73be") +
    coord_flip(expand = FALSE) +
    labs(
      x = NULL,
      y = NULL,
      title = glue("Number of retweets of the {top_number} most retweeted #{hashtag}")
    ) +
    theme_classic()

  ggsave(plot = g1, filename = file.path(save_dir, "top_retweet.jpg"),
         width = 7, height = 4)

  # Timeline
  g2 <- last_month_tweets %>%
    mutate(date = as_date(created_at)) %>%
    count(date) %>%
    ggplot() +
    aes(x = date, y = n) +
    geom_col(fill = "#1e73be") +
    labs(
      title = glue("Number of #{hashtag} tweets of last month"),
      x = NULL,
      y = NULL
    ) +
    theme_classic() +
    coord_cartesian(expand = FALSE)

  ggsave(plot = g2, filename = file.path(save_dir, "number_tweets.jpg"),
         width = 7, height = 4)

  # Post tweet
  if (post_tweet == TRUE) {
    post_tweet(
      status = text,
      media = c(file.path(save_dir, "top_retweet.jpg"),
                file.path(save_dir, "number_tweets.jpg")))
  }

  list(
    top_retweet = g1,
    number_tweets = g2,
    top_retweet_url = file.path(save_dir, "top_retweet.jpg"),
    number_tweets = file.path(save_dir, "number_tweets.jpg"),
    text = text
  )
}
