test_that("data frames survive the codec exactly", {
  df <- data.frame(
    d = c(0.1 + 0.2, 1 / 3, NA, NaN, Inf, -Inf),
    i = c(1L, NA, 3L, 4L, 5L, 6L),
    l = c(TRUE, FALSE, NA, TRUE, TRUE, FALSE),
    s = c("a", "é中", NA, "", "q\"uote", "back\\slash"),
    f = factor(c("x", "y", NA, "x", "z", "y"), levels = c("z", "y", "x")),
    o = factor(c("lo", "hi", "lo", "hi", "lo", "hi"), levels = c("lo", "hi"), ordered = TRUE),
    dt = as.Date("2026-11-09") + 0:5,
    ct = as.POSIXct("2026-11-09 10:00:00", tz = "UTC") + c(0, 0.5, 1, 2, NA, 3),
    stringsAsFactors = FALSE
  )
  df$lst <- list(1:2, NULL, "a", c(1.5, NA), TRUE, character())
  rownames(df) <- paste0("r", 1:6)
  back <- df_from_json(df_to_json(df))$data
  expect_identical(back, df)
  sub <- mtcars[c(3, 7), ]
  expect_identical(df_from_json(df_to_json(sub))$data, sub)
  auto <- data.frame(x = 1:3)
  expect_identical(df_from_json(df_to_json(auto))$data, auto)
})

test_that("doubles use the shortest exact representation", {
  set.seed(1)
  x <- c(rnorm(500), 2.62, 1e-300, 1e300, -0, 7)
  tok <- num_tokens(x)
  expect_identical(as.double(jsonlite::parse_json(paste0("[", paste(tok, collapse = ","), "]"),
                                                  simplifyVector = TRUE)), x)
  expect_equal(num_tokens(c(2.62, 7)), c("2.62", "7.0"))
})

test_that("metadata keeps doubles as doubles", {
  x <- list(a = 7, b = 2L, c = "s", d = c(1.5, 2), e = list(f = TRUE), g = mtcars[1:2, 1:3])
  back <- json_read(json_write(x))
  expect_identical(back, x)
})

test_that("long numeric columns are stored in binary, exactly", {
  set.seed(2)
  n <- binary_min_length + 5L
  df <- data.frame(d = c(NA, NaN, Inf, -Inf, rnorm(n - 4)), i = c(NA, seq_len(n - 1)))
  txt <- df_to_json(df)
  expect_match(txt, "f64le-shuffle-base64", fixed = TRUE)
  expect_match(txt, "i32le-shuffle-base64", fixed = TRUE)
  back <- df_from_json(txt)$data
  expect_identical(back, df)
  expect_true(is.na(back$d[1]) && !is.nan(back$d[1]))
  expect_true(is.nan(back$d[2]))
})
