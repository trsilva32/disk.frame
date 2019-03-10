#' Bring the disk.frame into R as data.table/data.frame
#' @param x a disk.frame
#' @param parallel if TRUE the collection is performed in parallel. By default if there are delayed/lazy steps then it will be parallel, otherwise it will not be in parallel. This is because parallel requires transferring data from background R session to the current R session and if there is no computation then it's better to avoid transferring data between session, hence parallel = F is a better choice
#' @param ... not used
#' @export
#' @importFrom data.table data.table as.data.table
#' @importFrom furrr future_map_dfr
#' @importFrom purrr map_dfr
#' @importFrom dplyr collect
#' @rdname collect
collect.disk.frame <- function(x, ..., parallel = !is.null(attr(x,"lazyfn"))) {
  chunk_ids = get_chunk_ids(x, strip_extension = F)
  
  if(nchunks(x) > 0) {
    if(parallel) {
      furrr::future_map_dfr(chunk_ids, ~disk.frame::get_chunk(x, .x))
      #future.apply::future_lapply(chunk_ids, function(.x) disk.frame::get_chunk(x, .x))
      #lapply(chunk_ids, function(chunk) get_chunk(x, chunk)) %>% rbindlist
    } else {
      purrr::map_dfr(1:nchunks(x), ~get_chunk(x, .x))
    }
  } else {
    data.table()
  }
}

#' Bring the disk.frame into R as list
#' @param simplify Should the result be simplified to array
#' @export
#' @rdname collect
collect_list <- function(x, simplify = F, parallel = !is.null(attr(df,"lazyfn"))) {
  df = x
  if(nchunks(df) > 0) {
    res <- NULL
    if (parallel) {
      res = furrr::future_map(1:nchunks(df), ~get_chunk.disk.frame(df, .x))
    } else {
      res = purrr::map(1:nchunks(df), ~get_chunk.disk.frame(df, .x))
    }
    if (simplify) {
      return(simplify2array(res))
    } else {
      return(res)
    }
  } else {
    list()
  }
}

