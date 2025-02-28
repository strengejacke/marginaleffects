#' Plot Conditional or Marginal Comparisons
#'
#' @description
#' Plot comparisons on the y-axis against values of one or more predictors (x-axis, colors/shapes, and facets).
#'
#' The `by` argument is used to plot marginal comparisons, that is, comparisons made on the original data, but averaged by subgroups. This is analogous to using the `by` argument in the `comparisons()` function.
#'
#' The `condition` argument is used to plot conditional comparisons, that is, comparisons made on a user-specified grid. This is analogous to using the `newdata` argument and `datagrid()` function in a `comparisons()` call.
#' 
#' All unspecified variables are held at their mean or mode. This includes grouping variables in mixed-effects models, so analysts who fit such models may want to specify the groups of interest using the `variables` argument, or supply model-specific arguments to compute population-level estimates. See details below.

#' See the "Plots" vignette and website for tutorials and information on how to customize plots:
#'
#' * https://marginaleffects.com/articles/plot.html
#' * https://marginaleffects.com
#' 
#' @param variables Name of the variable whose contrast we want to plot on the y-axis.
#' @param draw `TRUE` returns a `ggplot2` plot. `FALSE` returns a `data.frame` of the underlying data.
#' @inheritParams comparisons
#' @param newdata When `newdata` is `NULL`, the grid is determined by the `condition` argument. When `newdata` is not `NULL`, the argument behaves in the same way as in the `comparisons()` function.
#' @inheritParams plot_slopes
#' @inheritParams slopes
#' @template model_specific_arguments
#' @return A `ggplot2` object
#' @export
#' @examples
#' mod <- lm(mpg ~ hp * drat * factor(am), data = mtcars)
#' 
#' plot_comparisons(mod, variables = "hp", condition = "drat")
#'
#' plot_comparisons(mod, variables = "hp", condition = c("drat", "am"))
#' 
#' plot_comparisons(mod, variables = "hp", condition = list("am", "drat" = 3:5))
#' 
#' plot_comparisons(mod, variables = "am", condition = list("hp", "drat" = range))
#' 
#' plot_comparisons(mod, variables = "am", condition = list("hp", "drat" = "threenum"))
plot_comparisons <- function(model,
                             variables = NULL,
                             condition = NULL,
                             by = NULL,
                             newdata = NULL,
                             type = "response",
                             vcov = NULL,
                             conf_level = 0.95,
                             wts = NULL,
                             comparison = "difference",
                             transform = NULL,
                             rug = FALSE,
                             gray = FALSE,
                             draw = TRUE,
                             ...) {


    dots <- list(...)
    if ("effect" %in% names(dots)) {
        if (is.null(variables)) {
            variables <- dots[["effect"]]
        } else {
            insight::format_error("The `effect` argument has been renamed to `variables`.")
        }
    }
    if ("transform_post" %in% names(dots)) { # backward compatibility
        transform <- dots[["transform_post"]]
    }

    # order of the first few paragraphs is important
    scall <- rlang::enquo(newdata)
    newdata <- sanitize_newdata_call(scall, newdata, model)
    if (!is.null(wts) && is.null(by)) {
        insight::format_error("The `wts` argument requires a `by` argument.")
    }

    checkmate::assert_character(by, null.ok = TRUE, max.len = 3, min.len = 1, names = "unnamed")
    if ((!is.null(condition) && !is.null(by)) || (is.null(condition) && is.null(by))) {
        msg <- "One of the `condition` and `by` arguments must be supplied, but not both."
        insight::format_error(msg)
    }

    # sanity check
    checkmate::assert(
        checkmate::check_character(variables, names = "unnamed"),
        checkmate::check_list(variables, names = "unique"),
        .var.name = "variables")

    modeldata <- get_modeldata(
        model,
        additional_variables = c(names(condition), by),
        wts = wts)

    # mlr3 and tidymodels
    if (is.null(modeldata) || nrow(modeldata) == 0) {
        modeldata <- newdata
    }

    # conditional
    if (!is.null(condition)) {
        condition <- sanitize_condition(model, condition, variables, modeldata = modeldata)
        v_x <- condition$condition1
        v_color <- condition$condition2
        v_facet_1 <- condition$condition3
        v_facet_2 <- condition$condition4
        datplot <- comparisons(
            model,
            newdata = condition$newdata,
            type = type,
            vcov = vcov,
            conf_level = conf_level,
            by = FALSE,
            wts = wts,
            variables = variables,
            comparison = comparison,
            transform = transform,
            cross = FALSE,
            modeldata = modeldata,
            ...)
    }

    # marginal
    if (!is.null(by)) {
        newdata <- sanitize_newdata(
            model = model,
            newdata = newdata,
            modeldata = modeldata,
            by = by,
            wts = wts)
        datplot <- comparisons(
            model,
            by = by,
            newdata = newdata,
            type = type,
            vcov = vcov,
            conf_level = conf_level,
            variables = variables,
            wts = wts,
            comparison = comparison,
            transform = transform,
            cross = FALSE,
            modeldata = modeldata,
            ...)
        v_x <- by[[1]]
        v_color <- hush(by[[2]])
        v_facet_1 <- hush(by[[3]])
        v_facet_2 <- hush(by[[4]])
    }

    datplot <- plot_preprocess(datplot, v_x = v_x, v_color = v_color, v_facet_1 = v_facet_1, v_facet_2 = v_facet_2, condition = condition, modeldata = modeldata)

    # return immediately if the user doesn't want a plot
    if (isFALSE(draw)) {
        out <- as.data.frame(datplot)
        attr(out, "posterior_draws") <- attr(datplot, "posterior_draws")
        return(out)
    }
    
    # ggplot2
    insight::check_if_installed("ggplot2")
    p <- plot_build(datplot, v_x = v_x, v_color = v_color, v_facet_1 = v_facet_1, v_facet_2 = v_facet_2, gray = gray, rug = rug, modeldata = modeldata)
    p <- p + ggplot2::labs(x = v_x, y = sprintf("Comparison"))

    return(p)
}


#' `plot_comparisons()` is an alias to `plot_comparisons()`
#'
#' This alias is kept for backward compatibility.
#' @inherit plot_predictions
#' @keywords internal
#' @export
plot_cco <- function(...) {
    insight::format_warning("This function has been renamed to `plot_comparisons()`. The `plot_cco()` alias will be removed in a future release.")
    plot_comparisons(...)
}