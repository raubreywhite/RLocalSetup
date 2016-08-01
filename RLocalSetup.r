# 4.4
#
# Richard White
# r.aubrey.white@gmail.com
# github.com/raubreywhite/RLocalSetup
#
# Local setup of skeleton R analysis work

if(!exists("upgradeRLocalSetup")) upgradeRLocalSetup <- FALSE
if(upgradeRLocalSetup){
  try({
    if(!require(httr)){
      install.packages("httr", repos="http://cran.r-project.org")
    }

    l <- readChar("RLocalSetup.R", file.info("RLocalSetup.R")$size)
    lVer <- as.numeric(substr(l,3,5))
    print(paste0("CURRENT LOCAL VERSION ",lVer))

    r <- httr::GET("https://raw.githubusercontent.com/raubreywhite/RLocalSetup/master/RLocalSetup.r")
    r <- httr::content(r)
    rVer <- as.numeric(substr(r,3,5))
    print(paste0("CURRENT REMOTE VERSION ",rVer))

    if(rVer > lVer){
    	print(paste0("UPGRADING FROM ",lVer," to ",rVer))
      write(r, file="RLocalSetup.R")
      stopUpgrade <- TRUE
    }
  },TRUE)
}



# Adding R tools
AddRtools <- function(path="H:/Apps/Rtools"){
  if(path!="" & !devtools::find_rtools()){
    path <- gsub("/","\\\\",path)
    path <- paste0(path,"\\")
    for(i in 1:10) path <- gsub("\\\\\\\\","\\\\",path)
    currentPath <- Sys.getenv("PATH")
    newPath <- paste(currentPath,paste0(path,"\\bin"),paste0(path,"\\gcc-4.6.3\\bin"),sep=";")
    Sys.setenv(PATH=newPath)
  }
  return(devtools::find_rtools())
}


PandocInstalled <- function(){
  suppressWarnings(pandoc.installed <- system('pandoc -v')==0)
  if(pandoc.installed) return(TRUE)

  rstudio.environment.installed <- Sys.getenv("RSTUDIO_PANDOC")
  if(rstudio.environment.installed!=""){
    rstudio.environment.installed <- paste0('"',rstudio.environment.installed,'/pandoc" -v')
    suppressWarnings(rstudio.environment.installed <- system(rstudio.environment.installed)==0)
  } else rstudio.environment.installed <- FALSE
  if(rstudio.environment.installed) return(TRUE)

  suppressWarnings(rstudio.pandoc.installed <- system('"C:/Program Files/RStudio/bin/pandoc/pandoc" -v')==0)
  if(rstudio.pandoc.installed){
    Sys.setenv(RSTUDIO_PANDOC="C:/Program Files/RStudio/bin/pandoc")
  }
  if(rstudio.pandoc.installed) return(TRUE)

  return(FALSE)
}

Restore <- function(){
  install.packages(c("BH","XML","git2r","RCurl"))
  packrat::restore()
}

CreatePackage <- function(name="test",depends=NULL,imports=NULL){
  if(!suppressWarnings(suppressMessages(require(devtools)))){
    install.packages("devtools", repos="http://cran.r-project.org")
  }

  if(!suppressWarnings(suppressMessages(require(packrat)))){
    install.packages("packrat", repos="http://cran.r-project.org")
  } else packrat::off()

  print("CHECKING SYSTEM VARIABLES FOR RTOOLS LOCATION")
  if(!devtools::find_rtools()){
    stop("ERROR, R TOOLS NOT FOUND IN SYSTEM VARIABLES")
  }
  print("RTOOLS WORKING PROPERLY")

  depends <- unique(c(depends,c("ggplot2")))
  depends <- depends[depends!=""]
  imports <- unique(c(imports,"data.table","raubreywhite/RAWmisc","rstudio/revealjs"))
  imports <- imports[imports!=""]

  devtools::create(name)
  
  setwd(name)
  packrat::init(enter=FALSE)
  packrat::on(auto.snapshot=FALSE)
  setwd("..")
  
  file.remove(paste0(name,"/DESCRIPTION"))
  
  install.packages(c("stringr","devtools"))

  dependsGithub <- depends[grep("/",depends)]
  dependsCRAN <- depends[!depends %in% dependsGithub]

  importsGithub <- imports[grep("/",imports)]
  importsCRAN <- imports[!imports %in% importsGithub]

  depends <- stringr::str_split(depends,"/")
  for(i in 1:length(depends)) depends[[i]] <- depends[[i]][length(depends[[i]])]
  depends <- unlist(depends)

  imports <- stringr::str_split(imports,"/")
  for(i in 1:length(imports)) imports[[i]] <- imports[[i]][length(imports[[i]])]
  imports <- unlist(imports)

  devtools::create_description(name,extra=list(Package=name,Depends=depends,Imports=imports))
  file.remove(paste0(name,"/NAMESPACE"))
  write("exportPattern(\"^[^\\\\.]\")\nimport(data.table)",file=paste0(name,"/NAMESPACE"))
 
  if(length(dependsCRAN)>0) for(i in dependsCRAN){
    install.packages(i)
  }
  if(length(dependsGithub)>0) for(i in dependsGithub){
    devtools::install_github(i)
  }

  if(length(importsCRAN)>0) for(i in importsCRAN){
    install.packages(i)
  }
  if(length(importsGithub)>0) for(i in importsGithub){
    devtools::install_github(i)
  }

  packrat::snapshot()

  dir.create("code")

  dir.create("data_raw")
  dir.create("data_temp")
  dir.create("data_clean")

  dir.create("results_baked")
  dir.create("results_final")
  dir.create("reports_skeleton")
  dir.create("reports_formatted")
  dir.create("pres_skeleton")
  dir.create("pres_formatted")

  dir.create(paste0(name,"/inst"))
  dir.create(paste0(name,"/inst/extdata"))
  
  file <- system.file("extdata","pres.Rmd",package="RAWmisc")
  file.copy(file, paste0("pres_skeleton/pres.Rmd"), overwrite=TRUE)

  file <- system.file("extdata","report.Rmd",package="RAWmisc")
  file.copy(file, paste0("reports_skeleton/report.Rmd"), overwrite=TRUE)
  
  file <- system.file("extdata","american-medical-association.csl",package="RAWmisc")
  file.copy(file, paste0("reports_skeleton/american-medical-association.csl"), overwrite=TRUE)

  file <- system.file("extdata","references.bib",package="RAWmisc")
  file.copy(file, paste0("reports_skeleton/references.bib"), overwrite=TRUE)

  packrat::off()
  file.remove(".Rprofile")
  
  write("RPROJ <- list(PROJHOME = normalizePath(getwd()));print('Sourcing project-specific .Rprofile');print(RPROJ)",file=".Rprofile")
  write("Version: 1.0\n\nRestoreWorkspace: No\nSaveWorkspace: No\nAlwaysSaveHistory: No\n\nEnableCodeIndexing: Yes\nUseSpacesForTab: Yes\nNumSpacesForTab: 2\nEncoding: ISO8859-1\n\n\nRnwWeave: Sweave\nLaTeX: pdfLaTeX",file=paste0(name,".Rproj"))
  write(".Rproj.user\n.Rhistory\n.RData\nresults_temp/\nresults_final/\ndata_raw/\ndata_temp/\ndata_clean/\nreports_formatted/\npres_formatted/\npackrat/",file=".gitignore")

  write(
paste0("
setwd(RPROJ$PROJHOME)

# Change if you want local setup to be pulled from github
upgradeRLocalSetup <- FALSE
source(\"RLocalSetup.R\")

# Packrat
setwd(\"",name,"\")
suppressWarnings(packrat::on(auto.snapshot=FALSE))
setwd(\"..\")
#packrat::status()
#packrat::snapshot()

# new
isLinux <- length(grep(\"linux\",sessionInfo()$platform))>0
isRStudio <- Sys.getenv(\"RSTUDIO\") == \"1\"
msg <- function(p,m){
  if(length(grep(\"linux\",sessionInfo()$platform))>0) system(paste0('/log/log.sh \"',lubridate::now(tzone=\"CET\"),'@',p,'@',m,'\"'))
}
# Change if you want local setup to be pulled from github
upgradeRLocalSetup <- FALSE

if(isLinux){
  msg(\"",name,"\",\"RUN\",\"Beginning program\")
  if(!exists(\"RPROJ\")) RPROJ <- list(PROJHOME = normalizePath(\"/src/\"))

  setwd(RPROJ$PROJHOME)
  source(\"RLocalSetup.R\")
  
} else {
  Sys.setenv(R_TOOLS=\"C:\\\\Apps\\\\Rtools\")
  Sys.setenv(R_TOOLS_PATH=\"C:\\\\Apps\\\\Rtools\\\\bin;C:\\\\Apps\\\\Rtools\\\\gcc-4.6.3\\\\bin\")
  Sys.setenv(PATH=paste0(c(Sys.getenv(\"R_TOOLS_PATH\"),Sys.getenv(\"PATH\"),Sys.getenv(\"R_PATH\")),collapse=\";\"))
  Sys.setenv(RSTUDIO_PANDOC=\"C:/Apps/RStudio/bin/pandoc\")

  setwd(RPROJ$PROJHOME)
  source(\"RLocalSetup.R\")
  
  # Packrat
  setwd(\"",name,"\")
  suppressWarnings(packrat::on(auto.snapshot=FALSE))
  setwd(\"..\")
  #packrat::status()
  #packrat::snapshot()
  
  # Unload package
  try(devtools::unload(\"",name,"\"),TRUE)

  # Load package
  devtools::load_all(\"",name,"\")
}
# new end

library(data.table)
library(ggplot2)
library(foreach)
library(doParallel)
registerDoParallel()

assign(\"RUN_ALL\", TRUE, envir=globalenv())

fileSources = file.path(\"code\",list.files(\"code\",pattern=\"*.[rR]$\"))
sapply(fileSources,source,.GlobalEnv)

# Commit to Git
CommitToGit(paste0(\"Committing while loading at \",Sys.time()))

r <- git2r::repository()
git2r::summary(r)
git2r::contributions(r,by=\"author\")

# Your code starts here
tryCatch({
  print(\"Hello\")
  
  if(RUN_ALL) file.remove(\"results_baked/test.RDS\")
  bake(file=\"results_baked/test.RDS\",seed=4,kind=\"L'Ecuyer\",{
    foreach (i=1:10,
           .combine=c,
           .inorder=FALSE,
           .options.multicore=list(set.seed=TRUE)
    ) %dopar% {
      i
    } 
  }) -> p
  
  msg(\"",name,"\",\"RUN\",\"Main code finished\")
}, warning=function(war) {
  msg(\"",name,"\",\"WARN\",paste0(\"UNEXPECTEDLY finished with warning: \",war))
}, error=function(err) {
  msg(\"",name,"\",\"ERROR\",paste0(\"UNEXPECTEDLY finished with error: \",err))
}, finally={
}
)

# Text
RAWmisc::RmdToDOCX(\"reports_skeleton/report.Rmd\",paste0(\"reports_formatted/\",format(Sys.time(), \"%Y_%m_%d\"),\"_text.html\"), copyFrom=\"reports_skeleton\")

# Tables
RAWmisc::RmdToHTMLDOCX(\"reports_skeleton/report.Rmd\",paste0(\"reports_formatted/\",format(Sys.time(), \"%Y_%m_%d\"),\"_tables.html\"), copyFrom=\"reports_skeleton\")

RAWmisc::RmdToPres(inFile=\"pres_skeleton/pres.Rmd\",
                   outFile=\"pres_formatted/Presentation.html\",
                   copyFrom=\"pres_skeleton\")

msg(\"",name,"\",\"FINISHED\",\"Exiting R\")

"),file="Run.R")

  repoExists <- FALSE
  try({
    r <- git2r::repository(".")
    repoExists <- TRUE
  },TRUE)
  if(!repoExists){
    r <- git2r::init(".")
    text = paste0('git2r::config(r, user.name="',Sys.info()[["user"]],'", user.email="',Sys.info()[["user"]],'@fhi.no")')
    eval(parse(text=text))
    message("* Adding files and committing")
    paths <- unlist(git2r::status(r, verbose = FALSE))
    git2r::add(r, paths)
    git2r::commit(r, "Initial commit")
  }
}

CommitToGit <- function(message="This is a working version"){
  try({
    #r <- git2r::repository(".")
    r <- git2r::repository()
    text = paste0('git2r::config(r, user.name="',Sys.info()[["user"]],'", user.email="',Sys.info()[["user"]],'@fhi.no")')
    eval(parse(text=text))
    paths <- unlist(git2r::status(r,verbose = FALSE))
    git2r::add(r, paths)
    git2r::commit(r, message)
  },TRUE)
}

# making sure everything is where it shold be

if(!suppressWarnings(suppressMessages(require(packrat)))){
  install.packages("packrat", repos="http://cran.r-project.org")
} else packrat::off()

if(!suppressWarnings(suppressMessages(require(devtools)))){
  install.packages("devtools", repos="http://cran.r-project.org")
}

print("CHECKING SYSTEM VARIABLES FOR RTOOLS LOCATION")
if(!devtools::find_rtools()){
  stop("ERROR, R TOOLS NOT FOUND IN SYSTEM VARIABLES")
}
print("RTOOLS WORKING PROPERLY")

print("CHECKING SYSTEM VARIABLES FOR PANDOC LOCATION")
if(!PandocInstalled()){
    stop("ERROR; PANDOC NOT INSTALLED")
}
print("PANDOC WORKING PROPERLY")
