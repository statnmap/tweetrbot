#' Filter dataset for last month tweets only
#'
#' @param x Dataset of tweets
#' @param the_month Number of the month. Default to last month.
#' @param the_year Year to filter. Default to current year.
#'
#' @importFrom lubridate ymd_hms year today
#' @importFrom dplyr mutate filter
#'
#' @export

filter_month <- function(x, the_month, the_year) {
  # Filter for the last month
  if (missing(the_year)) {
    the_year <- year(today())
  }
  if (missing(the_month)) {
    the_month <- last_month()$last_month
    # Last year if last month is December
    if (the_month == 12) {the_year <- the_year - 1}
  }


  all_tweets %>%
    mutate(created_at = ymd_hms(created_at)) %>%
    filter(month(created_at) == the_month,
           year(created_at) == the_year,
           is_retweet == FALSE)
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
