# RLocalSetup
R local setup

Use this in conjunction with https://github.com/raubreywhite/Apps

# How to use

* Copy/paste two R scripst to your new project folder
* Open Initialise.R
* Set working directory and package name
* Run!

# How to install new packages

* Restart R within RStudio
* setwd("blah")
* packrat::on("packagename")
* install.packages("package")
* packrat::snapshot()
* Restart R within RStudio
* Edit package/DESCRIPTION file to include package as a dependency
