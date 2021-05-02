plot_element <- function(filename) {
    ele = read.table(filename, header=T)
    x <- seq(1, length(ele[[1]]))
    max_y = max(ele[,2:ncol(ele)])
    plot(x, xlab="Element number", type="n",
         ylab="Covalent radius (\uc5)", ylim=c(0, max_y))
    for (i in 2:ncol(ele)) {
        lines(x, ele[[i]], type="l", col=i )
    }
    legend(1, 2.5, names(ele)[2:ncol(ele)],  lty=c(1,1), col = seq(2,ncol(ele)))
}
