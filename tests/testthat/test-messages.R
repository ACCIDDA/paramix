test_that("format_message handles no args, named placeholders, and sprintf", {
  expect_equal(format_message("plain message"), "plain message")
  expect_equal(
    format_message("hello {name}!", name = "world"),
    "hello world!"
  )
  expect_equal(
    format_message("value: %d", 42L),
    "value: 42"
  )
})

test_that("paramix_condition attaches correct classes and fields", {
  err <- paramix_condition(
    "error",
    "test error",
    "TEST_ID",
    fields = list(code = 123L, message = "override")
  )
  expect_s3_class(err, "paramix_error")
  expect_s3_class(err, "error")
  expect_s3_class(err, "condition")
  expect_equal(err$id, "TEST_ID")
  expect_equal(err$code, 123L)
  expect_equal(err$message, "test error")

  warn <- paramix_condition(
    "warning",
    "test warning",
    "TEST_WARN",
    fields = list(flag = TRUE)
  )
  expect_s3_class(warn, "paramix_warning")
  expect_s3_class(warn, "warning")
  expect_s3_class(warn, "condition")
  expect_equal(warn$id, "TEST_WARN")
  expect_true(warn$flag)
})

test_that("stop_fmt_if signals paramix_error with template ID and fields", {
  dummy_template <- "failed for {item}"
  expect_no_error(stop_fmt_if(FALSE, dummy_template, item = "x"))

  err <- tryCatch(
    stop_fmt_if(TRUE, dummy_template, item = "x"),
    error = function(e) e
  )
  expect_s3_class(err, "paramix_error")
  expect_equal(err$id, "dummy_template")
  expect_equal(err$item, "x")
  expect_equal(err$message, "failed for x")
})

test_that("warn_fmt_if signals paramix_warning with template ID and fields", {
  dummy_warn_template <- "warning for {item}"
  expect_false(warn_fmt_if(FALSE, dummy_warn_template, item = "y"))

  warn <- NULL
  res <- withCallingHandlers(
    warn_fmt_if(TRUE, dummy_warn_template, item = "y"),
    warning = function(w) {
      warn <<- w
      invokeRestart("muffleWarning")
    }
  )
  expect_true(res)
  expect_s3_class(warn, "paramix_warning")
  expect_equal(warn$id, "dummy_warn_template")
  expect_equal(warn$item, "y")
  expect_equal(warn$message, "warning for y")
})

test_that("package functions throw paramix_error and paramix_warning classes", {
  expect_error(
    make_partition("A"),
    class = "paramix_error"
  )

  err <- tryCatch(
    make_partition("A"),
    error = function(e) e
  )
  expect_equal(err$id, "ERR_PARTITION_NOT_NUMERIC")
  expect_equal(err$name, "model_partition")

  expect_warning(
    make_partition(1:3, 3:1),
    class = "paramix_warning"
  )

  warn <- NULL
  withCallingHandlers(
    make_partition(1:3, 3:1),
    warning = function(w) {
      warn <<- w
      invokeRestart("muffleWarning")
    }
  )
  expect_equal(warn$id, "MSG_PARTITION_NOT_SORTED")

  expect_error(
    interpolate_opts(5),
    class = "paramix_error"
  )
})
