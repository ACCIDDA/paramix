test_that("`alembic` can handle any combination of function or data for f_param, f_pop", {
  f_p_fn <- function(a) 0.05 * a
  f_d_fn <- function(a) rep(1, length(a))

  f_p_df <- data.frame(age = 0:10, par = 0.05 * (0:10))
  f_d_df <- data.frame(age = 0:10, pop = c(rep(100, 10), 0))

  m_part <- c(0, 5, 10)
  o_part <- 0:10

  # function + function
  al_ff <- alembic(f_p_fn, f_d_fn, m_part, o_part)
  expect_s3_class(al_ff, "data.table")
  expect_true(nrow(al_ff) > 0)

  # function + data.frame
  al_fd <- alembic(f_p_fn, f_d_df, m_part, o_part)
  expect_s3_class(al_fd, "data.table")
  expect_equal(nrow(al_fd), nrow(al_ff))

  # data.frame + function
  al_df <- alembic(f_p_df, f_d_fn, m_part, o_part)
  expect_s3_class(al_df, "data.table")
  expect_equal(nrow(al_df), nrow(al_ff))

  # test data.frame + data.frame
  al_dd <- alembic(f_p_df, f_d_df, m_part, o_part)
  expect_s3_class(al_dd, "data.table")
  expect_equal(nrow(al_dd), nrow(al_ff))
})

test_that("`alembic` errors about partitions that do not have matching end points.", {
  f_p <- function(a) 0.02 * a
  f_d <- function(a) rep(1, length(a))

  expect_error(
    alembic(f_p, f_d, c(0, 5, 10), c(0, 2, 8)),
    "Partition boundaries must match"
  )
  expect_error(
    alembic(f_p, f_d, c(2, 5, 10), c(0, 5, 10)),
    "Partition boundaries must match"
  )
})

test_that(
  paste(
    "`alembic` return tables have model_partition,",
    "output_partition, weight, and relpop columns"
  ),
  {
    f_p <- function(a) 0.01 * a
    f_d <- function(a) rep(1, length(a))
    al <- alembic(f_p, f_d, c(0, 10, 20), seq(0, 20, by = 2))

    expect_named(
      al,
      c("model_partition", "output_partition", "weight", "relpop")
    )
    expect_type(al$model_partition, "double")
    expect_type(al$output_partition, "double")
    expect_type(al$weight, "double")
    expect_type(al$relpop, "double")
    expect_true(all(al$weight >= 0))
    expect_true(all(al$relpop >= 0))
  }
)

test_that("`alembic` return model_partition, output_partition forms a unique key", {
  f_p <- function(a) 0.01 * a
  f_d <- function(a) rep(1, length(a))
  al <- alembic(f_p, f_d, c(0, 10, 20, 30), seq(0, 30, by = 5))

  key_pairs <- paste(al$model_partition, al$output_partition, sep = "_")
  expect_equal(length(key_pairs), length(unique(key_pairs)))
})

test_that("`alembic` return model_partition, output_partition are sorted ascending.", {
  f_p <- function(a) 0.01 * a
  f_d <- function(a) rep(1, length(a))
  al <- alembic(f_p, f_d, c(0, 10, 20, 30), seq(0, 30, by = 2))

  expect_false(is.unsorted(al$model_partition))
  expect_false(is.unsorted(al$output_partition))
})

test_that("`blend` accurately extracts population-weighted model partition parameters", {
  # constant parameter function => blended values must equal the constant
  f_const <- function(a) rep(3.5, length(a))
  f_pop <- function(a) rep(1, length(a))
  al_const <- alembic(f_const, f_pop, c(0, 10, 30), seq(0, 30, by = 2))
  bl_const <- blend(al_const)

  expect_s3_class(bl_const, "data.table")
  expect_named(bl_const, c("model_partition", "value"))
  expect_equal(bl_const$value, c(3.5, 3.5), tolerance = 1e-6)

  # linear parameter f(x) = x, uniform population => mean is midpoint
  f_linear <- function(a) a
  al_lin <- alembic(f_linear, f_pop, c(0, 10, 20), seq(0, 20, by = 1))
  bl_lin <- blend(al_lin)
  expect_equal(bl_lin$value, c(5, 15), tolerance = 1e-6)
})

test_that("`distill` accurately and proportionally allocates model outcomes", {
  f_p <- function(a) 0.01 * a
  f_d <- function(a) rep(1, length(a))
  al <- alembic(f_p, f_d, c(0, 10, 20), seq(0, 20, by = 2))

  model_outcomes <- data.frame(
    model_partition = c(0, 10),
    value = c(100, 250)
  )

  distilled <- distill(al, model_outcomes)
  expect_s3_class(distilled, "data.table")
  expect_named(distilled, c("output_partition", "value"))

  # Total outcome mass is conserved
  expect_equal(
    sum(distilled$value),
    sum(model_outcomes$value),
    tolerance = 1e-6
  )

  # Error handling: outcome table has model partitions not in alembic
  bad_outcomes <- data.frame(
    model_partition = c(0, 10, 30),
    value = c(100, 200, 50)
  )
  expect_error(distill(al, bad_outcomes), "has groups not present")

  # Warning handling: outcome table does not cover all groups in alembic
  partial_outcomes <- data.frame(
    model_partition = c(0),
    value = c(100)
  )
  expect_warning(distill(al, partial_outcomes), "does not cover the groups")
})

test_that("`parameter_summary` returns correct comparison structure", {
  f_p <- function(a) 0.01 * a
  f_d <- function(a) rep(1, length(a))
  m_part <- c(0, 10, 20)

  ps <- parameter_summary(f_p, f_d, m_part, resolution = 21L)
  expect_s3_class(ps, "data.table")
  expect_named(ps, c("model_category", "x", "method", "value"))
  expect_setequal(
    levels(ps$method),
    c("f_val", "f_mid", "f_mean", "mean_f", "wm_f")
  )
  expect_equal(length(unique(ps$x)), 21L)
})

test_that("`distill_summary` returns comparison table across all imputation strategies", {
  f_p <- function(a) 0.01 * a
  f_d <- function(a) rep(1, length(a))
  m_part <- c(0, 10, 20)
  o_part <- seq(0, 20, by = 2)

  al <- alembic(f_p, f_d, m_part, o_part)
  model_outcomes <- data.frame(model_partition = c(0, 10), value = c(50, 150))

  ds <- distill_summary(al, model_outcomes)
  expect_s3_class(ds, "data.table")
  expect_named(ds, c("partition", "value", "method"))
  expect_setequal(
    levels(ds$method),
    c("f_mid", "f_mean", "mean_f", "wm_f")
  )
  expect_true(nrow(ds) > 0)
})
