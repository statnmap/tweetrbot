#' Update a tweet dataset with last information
#'
#' Update information of all statuses listed. At most, the last 90000.
#'
#' @param x dataset to update. Not used if path is set.
#' @param path Path to .rds file with saved dataset
#' @param statuses Tweet statuses to update
#' @param return_all Logical. TRUE returns the complete dataset,
#' FALSE returns data in statuses list (default).
#' @param overwrite Logical. Whether to overwrite rds file with updated data
#' @inheritParams rtweet::lookup_tweets
#'
#' @importFrom dplyr inner_join anti_join bind_rows slice n arrange
#' @importFrom rtweet lookup_tweets
#'
#' @export

update_data <- function(x, path, statuses, token = NULL, return_all = FALSE, overwrite = TRUE) {

  if (!missing(path)) {
    x <- readRDS(path)
  }
  if (!missing(statuses)) {
    x_filter <- x %>%
      filter(status_id %in% statuses) %>%
      slice(max(1, n() - 89999):n())
  } else {
    x_filter <- x %>%
      slice(max(1, n() - 89999):n()) #Twitter limit
  }

  # Update tweets infos
  up_filter_data <- lookup_tweets(x_filter$status_id, token = token)

  # Get supplementary variables
  x_filter_updated <- x_filter %>%
    select(status_id, names(x_filter)[
      !names(x_filter) %in% names(up_filter_data)]) %>%
    inner_join(up_filter_data, by = "status_id")

  # Complete statuses tweets
  x_filter_total <- x_filter %>%
    anti_join(x_filter_updated, by = "status_id") %>%
    bind_rows(x_filter_updated) %>%
    arrange(created_at)

  if (isTRUE(overwrite) & !missing(path) | isTRUE(return_all)) {
    # Get all tweets not updated
    x_total <- x %>%
      anti_join(x_filter_total, by = "status_id") %>%
      bind_rows(x_filter_total) %>%
      arrange(created_at)

    if (isTRUE(overwrite) & !missing(path)) {
      saveRDS(x_total, path)
    }
    if (isTRUE(return_all)) {
      return(x_total)
    } else {
      return(x_filter_total)
    }
  } else {
    return(x_filter_total)
  }
}
