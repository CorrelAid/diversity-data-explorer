#' @param string character vector of length 1 
#' @return numeric vector with each element the decimal equivalent of the raw vector that is created by memCompress
compress_for_ojs <- function(string) {
  if (length(string) != 1) stop("You can only compress a character vector of length 1.")
  # gzip 
  compressed_raw <-  memCompress(charToRaw(string), "gzip") # raw vector
  # convert each element of vector from hex to decimal
  # needed because the decompression in js expects it this way and not as hex
  # TODO: check whether an option in decompress function can also make hex acceptable
  compressed_decimal <- as.numeric(compressed_raw) 
  return(compressed_decimal)
}
