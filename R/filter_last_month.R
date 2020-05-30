#' Filter dataset for last month tweets only
#'
#' @param x Dataset of tweets
#' @param the_month Number of the month. Default to last month.
#'
#' @importFrom lubridate ymd_hms
#' @importFrom dplyr mutate filter
#'
#' @export

filter_month <- function(x, the_month) {
  # Filter for the last month
  if (missing(the_month)) {
    the_month <- last_month()$last_month
  }

  all_tweets %>%
    mutate(created_at = ymd_hms(created_at)) %>%
    filter(month(created_at) == the_month & is_retweet == FALSE)
}

#' What is last month
#'
#' @importFrom lubridate month today
#'
#' @export
#'
#' @examples
#' last_month()
last_month <- function() {
  current_month <- month(today())
  last_month <- ifelse(current_month == 1, 12, current_month - 1)
  last_month_name <- month.name[last_month]

  list(
    last_month = last_month,
    last_month_name = last_month_name
  )
}
