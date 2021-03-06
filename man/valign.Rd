% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/attributes.R
\name{valign}
\alias{valign}
\alias{valign<-}
\alias{set_valign}
\alias{valign.huxtable}
\alias{valign<-.huxtable}
\title{Vertical alignment}
\usage{
valign(ht)
valign(ht) <- value
set_valign(ht, row, col, value, byrow = FALSE)
}
\arguments{
\item{ht}{A huxtable.}

\item{value}{A character vector or matrix which may be 'top', 'middle', 'bottom' or \code{NA}. Set to \code{NA} to reset to the default.}

\item{row}{A row specifier. See \code{\link{rowspecs}} for details.}

\item{col}{An optional column specifier.}

\item{byrow}{If \code{TRUE}, fill in values by row rather than by column.}
}
\value{
For \code{valign}, the \code{valign} attribute.
For \code{set_valign}, the \code{ht} object.
}
\description{
Functions to get or set the vertical alignment property of huxtable table cells.
}
\details{
Vertical alignment may not work for short text in LaTeX. Defining row heights with \code{\link[=row_height]{row_height()}}
may help.
}
\examples{

ht <- huxtable(a = 1:3, b = 1:3)
valign(ht) <-  'bottom'
valign(ht)


ht <- huxtable(a = 1:3, b = 3:1)
ht2 <- set_valign(ht, 'bottom')
valign(ht2)
ht3 <- set_valign(ht, 1:2, 1, 'bottom')
valign(ht3)
ht4 <- set_valign(ht, 1:2, 1:2, c('bottom', 'bottom'), byrow = TRUE)
valign(ht4)
ht5 <- set_valign(ht, where(ht == 1), 'bottom')
valign(ht5)
}
