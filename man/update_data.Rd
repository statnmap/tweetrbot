% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/update_data.R
\name{update_data}
\alias{update_data}
\title{Update a tweet dataset with last information}
\usage{
update_data(
  x,
  path,
  statuses,
  token = NULL,
  return_all = FALSE,
  overwrite = TRUE
)
}
\arguments{
\item{x}{dataset to update. Not used if path is set.}

\item{path}{Path to .rds file with saved dataset}

\item{statuses}{Tweet statuses to update}

\item{token}{Expert use only. Use this to override authentication for
a single API call. In most cases you are better off changing the
default for all calls. See \code{\link[rtweet:auth_as]{auth_as()}} for details.}

\item{return_all}{Logical. TRUE returns the complete dataset,
FALSE returns data in statuses list (default).}

\item{overwrite}{Logical. Whether to overwrite rds file with updated data}
}
\description{
Update information of all statuses listed. At most, the last 90000.
}
