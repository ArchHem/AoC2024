library(memoise)

options(scipen = 999)

data_loader <- function(file_path) {

  input <- readLines(file_path)

  numbers <- unlist(strsplit(input, " "))

  result <- as.integer(numbers)

  return(result)
}


file_path <- "day11/day11input.txt" 
data <- data_loader(file_path)


blink <- memoise(function(stone, depth) {
  if (depth == 0) {
    return(1)
  }
  if (stone == 0) {
    return(blink(1, depth - 1))
  } else {
    digits <- ceiling(log10(stone + 1))
    if (digits %% 2 == 0) {
      n <- 10^(digits %/% 2)
      return(blink(stone %/% n, depth - 1) + blink(stone %% n, depth - 1))
    } else {
      return(blink(stone * 2024, depth - 1))
    }
  }
})

depth <- 75
result <- sum(sapply(data, blink, depth))
print(result)