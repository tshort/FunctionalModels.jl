a = read.csv("pendulum.csv", header = FALSE)

png(width = 800, height = 400)
par(mar = c(0,0,0,0))
for (i in seq(start = 1, to = nrow(a), by = 3)) {
    plot.new()
    plot.window(xlim = c(-1.05, 1.05), ylim = c(-1.05, 0), asp = 1)
    if (a[i,1] < 1.8) {
        lines(c(0,a[i,2]), c(0,a[i,3]))
    } 
    symbols(x = a[i,2], y = a[i,3], circle = 0.05,
            inches = FALSE,
            bg = "darkblue", fg = "darkblue",
            add = TRUE)
    ## points(x = a[i,2], y = a[i,3])
    x <- 1.06
    y <- 1.06
    lines(c(-x, -x, x, x, -x), c(0, -y, -y, 0, 0), col = "gray")
}
dev.off()

system("gm convert -loop 99 Rp*.png pendulum.gif")
file.remove(list.files(pattern="Rp.*.png"))
