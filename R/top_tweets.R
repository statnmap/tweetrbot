#' Create a tweet for top retweets and other stats
#'
#' @param all_tweets Table of tweets to explore
#' @param save_dir Path where to save images that will be tweet
#' @param post_tweet Logical. Whether to really tweet the content
#' @param top_number Numeric. Number of best retweeted tweets to show on the graph
#' @param hashtag Character. Which Twitter hashtag is followed
#' @param fill Vector of colors to be used in the graphics.
#'  Length 1 for all the same, or length 3 resp. for:
#'  top retweeted, tweets per day, contributors per day
#' @param token Every user should have their own Oauth (Twitter API) token.
#'  By default token = NULL this function looks for the path to a saved Twitter
#'  token via environment variables (which is what 'create_token()'
#'  sets up by default during initial token creation).
#'  For instruction on how to create a Twitter token see the tokens vignette,
#'  i.e., 'vignettes("auth", "rtweet")'.
#'
#' @export
#'
#' @importFrom lubridate month today ymd_hms as_date
#' @importFrom dplyr filter mutate top_n select arrange count group_by summarise
#' @importFrom glue glue
#' @importFrom ggplot2 ggplot aes geom_col coord_flip labs theme_classic ggsave coord_cartesian
#' @importFrom rtweet post_tweet
#' @importFrom stats reorder

top_tweets <- function(all_tweets, save_dir = tempdir(), post_tweet = TRUE,
                       top_number = 5, hashtag = "rspatial",
                       fill = c("#1e73be", "#BF223C", "#79C698"),
                       token = NULL) {

  if (length(fill) != 3) {fill <- rep(fill[1], 3)}

  # Filter for the last month
  current_month <- month(today())
  last_month <- ifelse(current_month == 1, 12, current_month - 1)
  last_month_name <- month.name[last_month]

  last_month_tweets <- all_tweets %>%
    mutate(created_at = ymd_hms(created_at)) %>%
    filter(month(created_at) == last_month & is_retweet == FALSE)

  # The most retweet
  most_tweet <- last_month_tweets %>%
    top_n(1, retweet_count) %>%
    mutate(tweet_url =
             sprintf("https://twitter.com/%s/status/%s",
                     screen_name, status_id)) %>%
    select(tweet_url, screen_name)

  # Add nb total de tweets et nb total de contributeurs
  text_top <- glue(
    "Most retweeted:",
    " {paste(paste(most_tweet$tweet_url, 'by', paste0('@', most_tweet$screen_name)), collapse = ', ')}.")

  g1 <- last_month_tweets %>%
    top_n(top_number, retweet_count) %>%
    arrange(desc(retweet_count)) %>%
    mutate(name_tweet = paste(1:n(), screen_name, sep = " - ")) %>%
    ggplot() +
    aes(x = reorder(name_tweet, retweet_count), y = retweet_count) +
    geom_col(fill = fill[1]) +
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
    geom_col(fill = fill[2]) +
    labs(
      title = glue("Number of #{hashtag} tweets in {last_month_name}"),
      x = NULL,
      y = NULL
    ) +
    theme_classic() +
    coord_cartesian(expand = FALSE)

  ggsave(plot = g2, filename = file.path(save_dir, "number_tweets.jpg"),
         width = 7, height = 4)

  # Nombre total de contributeurs par jour
  n_tweets <- nrow(last_month_tweets)
  n_contributors <- length(unique(last_month_tweets$screen_name))
  text_contributors <- glue("Summary of {last_month_name} #{hashtag}: {n_tweets} tweets, {n_contributors} different contributors.")

  # > graph
  g3 <- last_month_tweets %>%
    mutate(date = as_date(created_at)) %>%
    group_by(date) %>%
    summarise(contributors = length(unique(screen_name))) %>%
    ggplot() +
    aes(x = date, y = contributors) +
    geom_col(fill = fill[3]) +
    labs(
      title = glue("Number of unique contributors of #{hashtag} in {last_month_name}"),
      x = NULL,
      y = NULL
    ) +
    theme_classic() +
    coord_cartesian(expand = FALSE)

  ggsave(plot = g3, filename = file.path(save_dir, "number_contributors.jpg"),
         width = 7, height = 4)

  text_tweet <- glue(text_contributors, "\n\n", text_top)

  # Post tweet
  if (post_tweet == TRUE) {
    post_tweet(
      status = text_tweet,
      media = c(file.path(save_dir, "number_contributors.jpg"),
                file.path(save_dir, "top_retweet.jpg"),
                file.path(save_dir, "number_tweets.jpg")),
      token = token)
  }

  list(
    top_retweet = g1,
    number_tweets = g2,
    number_contributors = g3,
    top_retweet_url = file.path(save_dir, "top_retweet.jpg"),
    number_tweets = file.path(save_dir, "number_tweets.jpg"),
    number_contributors = file.path(save_dir, "number_contributors.jpg"),
    text_top = text_top,
    text_contributors = text_contributors,
    text_tweet = text_tweet
  )
}
