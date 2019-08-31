#' Retrieve number of followers and tweets
#'
#' @param user user names or user IDs
#' @param dir Directory where to save data
#' @param timeline_file timeline filename relative to dir
#' @param log Logical. log file
#' @param logfile lofile name relative to dir
#'
#' @importFrom dplyr tibble bind_rows arrange distinct
#' @importFrom rtweet get_timeline
#'
#' @export
get_account_info <- function(user = "talk_rspatial",
                             dir = ".",
                            timeline_file = "timeline_rspatial.rds",
                            log = TRUE, logfile = "rtweet_info.log") {
  if (!dir.exists(dir)) {
    stop(paste("dir: '", dir, "' does not exist. There no directory to retrieve files from."))
  }

  # For logs
  if (isTRUE(log)) {
    sink(file = file.path(dir, logfile), append = FALSE)
  }

  # Get last tweet only
  last_tweet <- get_timeline(user, n = 1)
  # Get interesting information
  timeline <- tibble(
    # Time of retrieval
    date = Sys.time(),
    # Number of followers
    followers_count = last_tweet$followers_count,
    # Tweets of my account
    statuses_count = last_tweet$statuses_count
  )

  # Add to the existing database
  if (isTRUE(log)) {
    cat("Add new timeline to info database\n") # for log
  }

  # tweets_file <- "tweets_rspatial.rds"
  if (file.exists(file.path(dir, timeline_file))) {
    old_timeline <- readRDS(file.path(dir, timeline_file))
    newold_timeline <- timeline %>%
      bind_rows(old_timeline) %>%
      arrange(desc(date)) %>% # TRUE first
      distinct()
  } else {
    newold_timeline <- timeline
  }
  saveRDS(newold_timeline, file.path(dir, timeline_file))

  # Stop sink
  if (isTRUE(log)) {
    sink(file = NULL, append = FALSE)
  }

  # Return complete timeline
  return(newold_timeline)
}
