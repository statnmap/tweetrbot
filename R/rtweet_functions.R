#'  Retrieve tweets and store locally
#'
#' @param query search tweet query
#' @param n_tweets n_tweets
#' @param dir Path where everything will be saved
#' @param tweets_file tweets_file path name relative to dir
#' @param complete_tweets_file complete_tweets_file path name relative to dir
#' @param log Logical
#' @param logfile logfile path name relative to dir
#' @param loop_pid_file loop_pid_file path name relative to dir
#' @param token Every user should have their own Oauth (Twitter API) token.
#'  By default token = NULL this function looks for the path to a saved Twitter
#'  token via environment variables (which is what 'create_token()'
#'  sets up by default during initial token creation).
#'  For instruction on how to create a Twitter token see the tokens vignette,
#'  i.e., 'vignettes("auth", "rtweet")'.
#'
#' @importFrom rtweet search_tweets
#' @importFrom dplyr mutate bind_rows arrange distinct desc
#' @importFrom dplyr group_by case_when ungroup
#'
#' @export
get_and_store <- function(
  query = "#rspatial", n_tweets = 20,
  dir = ".",
  tweets_file = "tweets_rspatial.rds",
  complete_tweets_file = "complete_tweets_rspatial.rds",
  log = TRUE, logfile = "rtweet_console.log",
  loop_pid_file = "loop_pid.log",
  token = NULL) {

  if (!dir.exists(dir)) {dir.create(dir)}

  # For logs
  if (isTRUE(log)) {
    # Read log PID to verify no running process
    if (file.exists(file.path(dir, loop_pid_file))) {
      loop_pid <- readLines(file.path(dir, loop_pid_file))
      # append log if loop is running
      if (length(loop_pid) != 0)  {
		    append <- TRUE
		  } else {
		  	append <- FALSE
		  }
	  } else {
	  	append <- FALSE
	  }
    sink(file = file.path(dir, logfile), append = append)
  }

  # Retrieve tweets for one hashtag
  if (isTRUE(log)) {
    cat("--- get_and_store : Retrieve tweets ---\n") # for log
  }

  new_tweets <- search_tweets(
    query, n = n_tweets, include_rts = FALSE,
    token = token
  ) %>%
    mutate(
      retweet_order = NA_real_,
      bot_retweet = FALSE)

  # Add to the existing database
  if (isTRUE(log)) {
    cat("--- get_and_store : Add tweets to to-tweet database ---\n") # for log
  }
  if (file.exists(file.path(dir, tweets_file))) {
    old_tweets <- readRDS(file.path(dir, tweets_file))
    newold_tweets <- new_tweets %>%
      bind_rows(old_tweets) %>%
        # arrange(desc(bot_retweet)) # TRUE first but not NA...
        group_by(status_id) %>%
        mutate(bot_retweet = case_when(
          any(is.na(bot_retweet)) ~ NA, # failed retweet
          any(bot_retweet == TRUE) ~ TRUE, # already retweet
          all(bot_retweet == FALSE) ~ FALSE)) %>% # not retweet
        ungroup() %>%
        distinct(status_id, .keep_all = TRUE)
  } else {
    newold_tweets <- new_tweets
  }
  saveRDS(newold_tweets, file.path(dir, tweets_file))

  # Add to the complete database
  if (isTRUE(log)) {
    cat("--- get_and_store : Add tweets to complete database ---\n") # for log
  }
  if (file.exists(file.path(dir, complete_tweets_file))) {
    complete_old_tweets <- readRDS(file.path(dir, complete_tweets_file))
    complete_newold_tweets <- new_tweets %>%
      bind_rows(complete_old_tweets) %>%
      distinct(status_id, .keep_all = TRUE)
  } else {
    complete_newold_tweets <- new_tweets
  }
  saveRDS(complete_newold_tweets, file.path(dir, complete_tweets_file))

  # Stop sink
  if (isTRUE(log)) {
    sink(file = NULL, append = FALSE)
  }
  return(0)
}

#' Retweet and update the database of tweets to tweet
#'
#' @param dir Directory where everything will be saved
#' @param tweets_file tweets_file path name relative to dir
#' @param complete_tweets_file complete_tweets_file path name relative to dir
#' @param log Logical
#' @param logfile logfile path name relative to dir
#' @param loop_pid_file loop_pid_file path name relative to dir
#' @param tweets_failed_file tweets_failed_file path name relative to dir
#' @param n_tweets n_tweets
#' @param n_limit n_limit
#' @param sys_sleep sys_sleep
#' @param debug Logical. Use TRUE to avoid tweeting while debugging
#' @param token Every user should have their own Oauth (Twitter API) token.
#'  By default token = NULL this function looks for the path to a saved Twitter
#'  token via environment variables (which is what 'create_token()'
#'  sets up by default during initial token creation).
#'  For instruction on how to create a Twitter token see the tokens vignette,
#'  i.e., 'vignettes("auth", "rtweet")'.
#'
#' @importFrom dplyr filter arrange filter mutate select desc everything
#' @importFrom dplyr bind_rows distinct slice n group_by ungroup case_when
#' @importFrom rtweet post_tweet
#' @importFrom ps ps_handle ps_name ps_kill ps_is_running
#'
#' @export
retweet_and_update <- function(
  dir = ".",
  tweets_file = "tweets_rspatial.rds",
  complete_tweets_file = "complete_tweets_rspatial.rds",
  log = TRUE, logfile = "rtweet_console.log",
  loop_pid_file = "loop_pid.log",
  tweets_failed_file = "tweets_failed_rspatial.rds",
  n_tweets = 20, n_limit = 3, sys_sleep = 600,
  debug = FALSE, token = NULL
){

  if (!dir.exists(dir)) {
    stop(paste("dir: '", dir, "' does not exist. There no directory to retrieve files from."))
  }

  # Get current PID
  current_pid <- as.character(Sys.getpid())

  # Read log PID to verify no running process
  # loop_pid_file <- "loop_pid.log"
  if (!file.exists(file.path(dir, loop_pid_file))) {
    file.create(file.path(dir, loop_pid_file))
  }
  loop_pid <- readLines(file.path(dir, loop_pid_file))

  # Run loop only if not already running
  if (length(loop_pid) != 0)  {
    # Verify pid exists
		pid <- as.integer(loop_pid)
		test_pid <- try(ps_handle(pid), silent = TRUE)
		# Does not exists
		if (class(test_pid) == "try-error") {
		  file.remove(file.path(dir, loop_pid_file))
		  file.create(file.path(dir, loop_pid_file))
		} else if (!ps_name(test_pid) %in% c("R", "Rscript")) {
		  # Not R process
		  file.remove(file.path(dir, loop_pid_file))
		  file.create(file.path(dir, loop_pid_file))
		} else if (!ps_is_running(test_pid)) {
		  # Not running
		  ps_kill(test_pid)
		  file.remove(file.path(dir, loop_pid_file))
		  file.create(file.path(dir, loop_pid_file))
		} else {
  		# For logs
	  	if (isTRUE(log)) {
		    sink(file = file.path(dir, logfile), append = TRUE)
        cat("--- A new process tried to start but loop was already running ---\n") # for log
      }
      return(NULL)
    }
  }

  # For logs
  if (isTRUE(log)) {
    sink(file = file.path(dir, logfile), append = FALSE)
  }

  if (isTRUE(log)) {
   cat("Start the loop -", as.character(Sys.time()), "\n") # for log
  }
  # Fill the log file to prevent other process
  writeLines(current_pid, file.path(dir, loop_pid_file))

  # Add a column to database to define retweeting order
  to_tweets_filter <- readRDS(file.path(dir, tweets_file)) %>%
    filter(bot_retweet == FALSE)

  # Retweet if non empty
  if (nrow(to_tweets_filter) != 0) {
    to_tweets <- to_tweets_filter %>%
      arrange(desc(created_at)) %>% # older at the end
      mutate(retweet_order = rev(1:n())) %>% # older tweeted first
      select(retweet_order, bot_retweet, everything())

    # Retweet loop
    for (i in sort(to_tweets$retweet_order)) {
      if (isTRUE(log)) {
        cat("Loop: ", i, "/", max(to_tweets$retweet_order), "\n") # for log
      }
      # which to retweet
      w.id <- which(to_tweets$retweet_order == i)
      print(paste(i, "- Retweet: N=",
                  to_tweets$retweet_order[w.id],
                  "-",
                  substr(to_tweets$text[w.id], 1, 180)))
      retweet_id <- to_tweets$status_id[w.id]
      # Retweet
      if (!isTRUE(debug)) {
        if (isTRUE(log)) {
          cat("Loop : let's tweet !", as.character(Sys.time()), "\n")
        }
        r <- post_tweet(retweet_id = retweet_id, token = token)
      } else {
        cat("Loop : debug mode activated, not tweeted\n")
        r <- list()
        r$status_code <- sample(c(200, 200, 404), 1)
      }
      # Change status
      if (r$status_code == 200) {
        # status OK
        to_tweets$bot_retweet[w.id] <- TRUE
        if (isTRUE(log)) {
          cat("Loop : status ok -", as.character(Sys.time()), "\n")
        }
      } else {
        # status not OK
        to_tweets$bot_retweet[w.id] <- NA
        if (isTRUE(log)) {
          cat("Loop : status failed -", as.character(Sys.time()), "\n")
        }
      }
      #   # Wait before the following retweet to avoid to be ban
      #   # Sys.sleep(60*10) # Sleep 10 minutes
      #   Sys.sleep(sys_sleep)
      # }

      # Save failure in other database
      failed_tweets <- to_tweets %>%
        filter(is.na(bot_retweet))

      # _Add failed to the existing database
      if (file.exists(file.path(dir, tweets_failed_file))) {
        old_failed_tweets <- readRDS(file.path(dir, tweets_failed_file))
        newold_failed_tweets <- failed_tweets %>%
          bind_rows(old_failed_tweets) %>%
          distinct(status_id, .keep_all = TRUE)
      } else {
        newold_failed_tweets <- failed_tweets
      }
      saveRDS(newold_failed_tweets, file.path(dir, tweets_failed_file))
      if (isTRUE(log)) {
        cat("Loop : save failed tweets\n")
      }

      # Read current dataset on disk again (in case there was an update)
      current_tweets <- readRDS(file.path(dir, tweets_file))
      # Remove duplicates, keep retweet = TRUE (first in list)
      updated_tweets <- to_tweets %>%
        bind_rows(current_tweets) %>%
        # arrange(desc(bot_retweet)) # TRUE first but not NA...
        group_by(status_id) %>%
        mutate(bot_retweet = case_when(
          any(is.na(bot_retweet)) ~ NA, # failed retweet
          any(bot_retweet == TRUE) ~ TRUE, # already retweet
          all(bot_retweet == FALSE) ~ FALSE)) %>% # not retweet
        ungroup() %>%
        distinct(status_id, .keep_all = TRUE)
      # Remove data from the to-tweets database if number is bigger than 'n_limit' and already retweeted
      if (nrow(updated_tweets) > (n_tweets * n_limit)) {
        updated_tweets <- updated_tweets %>%
          arrange(desc(created_at)) %>%
          slice(1:(n_tweets * n_limit))
      }
      # Save updated list of tweets
      saveRDS(updated_tweets, file.path(dir, tweets_file))
      if (isTRUE(log)) {
        cat("Loop : save updated database\n")
      }

      # Wait before the following retweet to avoid to be ban
      # Sys.sleep(60*10) # Sleep 10 minutes
      Sys.sleep(sys_sleep)
    }
  } else {
    cat("Loop : Nothing to tweet", as.character(Sys.time()), "\n")
  }

  # remove pid when loop finished
  file.remove(file.path(dir, loop_pid_file))
  cat("Loop : Removed PID file\n")

  # Stop sink
  if (isTRUE(log)) {
    sink(file = NULL, append = FALSE)
  }
  return(0)
}
