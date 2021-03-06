
# basic huxtable creation --------------------------------------------------------------------------

#' @import assertthat
NULL


#' Create a huxtable
#'
#' `huxtable`, or `hux`, creates a huxtable object.
#'
#' @param ... For `huxtable`, named list of values as in [data.frame()]. For `as_huxtable`,
#'   extra arguments.
#' @param add_colnames If `TRUE`, add a first row of column names to the huxtable.
#' @param add_rownames If `TRUE`, add a first column of row names, named 'rownames', to the huxtable.
#' @param autoformat If `TRUE`, automatically format columns by type. See below.
#'
#' @return An object of class `huxtable`.
#' @export
#' @section Automatic formatting:
#'
#' If `autoformat` is `TRUE`, then columns will have [number_format()] and [align()] properties
#' set automatically, as follows:
#'
#' * Integer columns will have `number_format` set to 0.
#' * Other numeric columns will have `number_format` set to \code{"\%.3g"}.
#' * All other columns will have `number_format` set to `NA` (no formatting).
#' * Integer, `Date` and date-time (i.e. `POSIXct` and `POSIXlt`) columns will be right-aligned.
#' * Other numeric columns will be aligned on `options("OutDec")`, usually `"."`.
#' * Other columns will be left aligned.
#'
#' You can change these defaults by editing `options("huxtable.autoformat_number_format")` and
#' `options("huxtable.autoformat_align")`. See [huxtable-package] for more details.
#'
#' Automatic alignment also applies to column headers if `add_colnames` is `TRUE`; headers of
#' columns aligned on a decimal point will be right-aligned. Automatic number formatting does not
#' apply to column headers.
#'
#' @details
#' If you use `add_colnames` or `add_rownames`, be aware that these will shift your rows and columns
#' along by one: your old row/column 1 will now be row/column 2, etc.
#'
#' `add_colnames` currently defaults to `FALSE`, but this will change in future. You can set
#' the default globally by setting `options("huxtable.add_colnames")` to `TRUE` or `FALSE`.
#'
#'
#' @examples
#' ht <- huxtable(column1 = 1:5, column2 = letters[1:5])
huxtable <- function (
        ...,
        add_colnames = getOption("huxtable.add_colnames", FALSE),
        add_rownames = FALSE,
        autoformat   = getOption('huxtable.autoformat', TRUE)
      ) {
  assert_that(is.flag(add_colnames), is.flag(add_rownames), is.flag(autoformat))

  df_args <- list(..., stringsAsFactors = FALSE, check.names = FALSE)
  if (R.version$major >= 3 && R.version$minor >= 3) df_args$fix.empty.names <- FALSE
  ht <- do.call(data.frame, df_args)
  ht <- as_huxtable(ht, add_colnames = add_colnames, add_rownames = add_rownames,
        autoformat = autoformat)

  ht
}


#' @export
#' @rdname huxtable
hux <- huxtable


#' @param x An object to convert to a huxtable.
#'
#' @export
#' @details
#' `as_huxtable` and `as_hux` convert an object to a huxtable.
#' Conversion methods exist for data frames, tables, ftables, matrices and (most) vectors.
#' @examples
#' dfr <- data.frame(a = 1:5, b = letters[1:5], stringsAsFactors = FALSE)
#' as_huxtable(dfr)
#'
#' @rdname huxtable
as_huxtable <- function (x, ...) UseMethod('as_huxtable')


#' @export
#' @rdname huxtable
as_hux <- as_huxtable


#' @export
#' @rdname huxtable
as_huxtable.default <- function (
        x,
        add_colnames = getOption("huxtable.add_colnames", FALSE),
        add_rownames = FALSE,
        autoformat   = getOption("huxtable.autoformat", TRUE),
        ...
      ) {
  assert_that(is.flag(add_colnames), is.flag(add_rownames), is.flag(autoformat))
  x <- as.data.frame(x, stringsAsFactors = FALSE)
  for (a in setdiff(huxtable_cell_attrs, 'number_format')) {
    attr(x, a) <- matrix(NA, nrow(x), ncol(x))
  }
  for (a in huxtable_col_attrs) {
    attr(x, a) <- rep(NA, ncol(x))
  }
  for (a in huxtable_row_attrs) {
    attr(x, a) <- rep(NA, nrow(x))
  }
  for (a in huxtable_table_attrs) {
    attr(x, a) <- NA
  }
  attr(x, 'number_format') <- matrix(list(NA), nrow(x), ncol(x))
  for (a in names(huxtable_env$huxtable_default_attrs)) {
    attr(x, a)[] <- huxtable_env$huxtable_default_attrs[[a]]  # [[ indexing matters here
  }

  class(x) <- c('huxtable', class(x))

  col_classes <- sapply(x, function (col) class(col)[1])
  if (autoformat) {
    dfn <- getOption('huxtable.autoformat_number_format', list())
    for (cn in seq_len(ncol(x))) {
      # double [[ matters for getting underlying object; also want only most specific class:
      cls <- col_classes[cn]
      number_format(x)[, cn] <- dfn[[cls]] %||% NA
    }
  }

  # order matters here. We want original rownames, not anything else.
  if (add_rownames) x <- add_rownames(x, preserve_rownames = FALSE)
  if (add_colnames) x <- add_colnames(x)
  # this bit comes after add_colnames so that column headers also get aligned:
  if (autoformat) {
    dfa <- getOption('huxtable.autoformat_align', list())
    for (cn in seq_len(ncol(x))) {
      cls <- col_classes[cn]
      autoal <- dfa[[cls]] %||% NA
      align(x)[, cn] <- autoal
      if (add_colnames && ! autoal %in% c("left", "right", "center", "centre", NA)) {
        align(x)[1, cn] <- "right"
      }
    }
  }

  x <- set_attr_dimnames(x)
  x
}


#' @export
as_huxtable.huxtable <- function (x, ...) x


#' @export
as_huxtable.table <- function (x, add_colnames = TRUE, add_rownames = TRUE, ...) {
  ht <- as_huxtable(unclass(x), add_colnames, add_rownames, ...)
  if (add_rownames) {
    ht[1, 1] <- ""
  }

  ht
}


#' @export
as_huxtable.ftable <- function(x, ...) {
  ht <- as_huxtable(format(x, quote = FALSE), ...)
  number_format(ht) <- 0
  ht
}


#' @export
as_huxtable.numeric <- function (x, ...) {
  # use default otherwise matrix has class e.g. c('matrix', 'numeric') so we recurse
  as_huxtable.default(as.matrix(x), ...)
}

#' @export
as_huxtable.character <- as_huxtable.numeric

#' @export
as_huxtable.logical   <- as_huxtable.numeric

#' @export
as_huxtable.complex   <- as_huxtable.numeric

#' @export
#' @rdname huxtable
is_huxtable <- function (x) inherits(x, 'huxtable')

#' @export
#' @rdname huxtable
is_hux <- is_huxtable
