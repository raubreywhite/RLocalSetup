# 1.7
#
# Richard White
# r.aubrey.white@gmail.com
# github.com/raubreywhite/RLocalSetup
#
# Local setup of skeleton R analysis work

rm(list=ls())

try({
  if(!require(httr)){
    install.packages("httr", repos="http://cran.r-project.org")
  }

  l <- readChar("RLocalSetup.R", file.info("RLocalSetup.R")$size)
  r <- httr::GET("https://raw.githubusercontent.com/raubreywhite/RLocalSetup/master/RLocalSetup.r")
  r <- httr::content(r)
  
  lVer <- as.numeric(substr(l,3,5))
  rVer <- as.numeric(substr(r,3,5))
  print(paste0("CURRENT LOCAL VERSION ",lVer))
  print(paste0("CURRENT REMOTE VERSION ",rVer))
  if(rVer > lVer){
  	print(paste0("UPGRADING FROM ",lVer," to ",rVer))
    write(r, file="RLocalSetup.R")
  }
},TRUE)

if(!require(packrat)){
  install.packages("packrat", repos="http://cran.r-project.org")
} else packrat::off()

if(!require(devtools)){
  install.packages("devtools", repos="http://cran.r-project.org")
}

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

if(AddRtools()){
  print("RTOOLS WORKING PROPERLY")
} else {
  print("ERROR, R TOOLS NOT INSTALLED INTO H:/Apps/Rtools")
}

CreatePackage <- function(name="test",depends=NULL,imports=NULL){
  depends <- unique(c(depends,c("raubreywhite/RAWmisc","raubreywhite/SMAOgraphs")))
  depends <- depends[depends!=""]
  imports <- unique(c(imports,"data.table"))
  imports <- imports[imports!=""]
  
  devtools::create(name)
  packrat::init(name, enter=FALSE)
  packrat::on(name)
  
  install.packages("devtools")
  install.packages("stringr")
  
  file.remove(paste0(name,"/DESCRIPTION"))
  
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
  dir.create("packages")
  packrat::set_opts(local.repos =paste0(getwd(),"/packages"))
  
  if(length(dependsCRAN)>0) for(i in dependsCRAN){
    install.packages(i)
  }
  if(length(dependsGithub)>0) for(i in dependsGithub){
    temp <- devtools:::github_remote(i)
    bundle <- devtools:::remote_download.github_remote(temp)
    src <- devtools:::source_pkg(bundle)
    devtools::build(src,path=paste0(getwd(),"/packages"))
    #devtools:::add_metadata(src, devtools:::remote_metadata.github_remote(temp, bundle, src))
    #file.copy(src,"packages",recursive=TRUE)
    packrat::install_github(i)
  }
  
  if(length(importsCRAN)>0) for(i in importsCRAN){
    install.packages(i)
  }
  if(length(importsGithub)>0) for(i in importsGithub){
    temp <- devtools:::github_remote(i)
    bundle <- devtools:::remote_download.github_remote(temp)
    src <- devtools:::source_pkg(bundle)
    devtools::build(src,path=paste0(getwd(),"/packages"))
    packrat::install_github(i)
  }
  
  packrat::snapshot()
  packrat::restore()
  
  dir.create("results")
  
  dir.create(paste0(name,"/inst"))
  dir.create(paste0(name,"/inst/extdata"))
  
  file <- system.file("extdata","report.Rmd",package="RAWmisc")
  file.copy(file, paste0(name,"/inst/extdata/report.Rmd"), overwrite=TRUE)
  
  file <- system.file("extdata","american-medical-association.csl",package="RAWmisc")
  file.copy(file, paste0(name,"/inst/extdata/american-medical-association.csl"), overwrite=TRUE)
  
  file <- system.file("extdata","references.bib",package="RAWmisc")
  file.copy(file, paste0(name,"/inst/extdata/references.bib"), overwrite=TRUE)
  
  packrat::off()
  
  write("Version: 1.0\n\nRestoreWorkspace: No\nSaveWorkspace: No\nAlwaysSaveHistory: No\n\nEnableCodeIndexing: Yes\nUseSpacesForTab: Yes\nNumSpacesForTab: 2\nEncoding: ISO8859-1\n\n\nRnwWeave: Sweave\nLaTeX: pdfLaTeX",file=paste0(name,".Rproj"))
  write(".Rproj.user\n.Rhistory\n.RData\npackages/\nresults/",file=".gitignore")
  write(".Rproj.user\n.Rhistory\n.RData\npackrat/",file=paste0(name,"/.gitignore"))
  
  write("
CleanData <- function(){
  data <- data.frame(x=rnorm(100),y=rnorm(100))
  return(data)
}",file=paste0(name,"/R/CleanData.R"))
  
  write("
FigureTest <- function(data){
  q <- ggplot(data, aes(x=x, y=y))
  q <- q + geom_point()
  q <- SMAOgraphs::SMAOFormatGGPlot(q)
  SMAOgraphs::SMAOpng(\"results/test.png\")
  print(q)
  dev.off()
}",file=paste0(name,"/R/Figures.R"))
  
  write(
paste0("
setwd(\"",getwd(),"\")

source(\"RLocalSetup.R\")

LoadPackage(\"",name,"\")
Libraries()

data <- CleanData()
FigureTest(data)

file <- system.file(\"extdata\",\"report.Rmd\",package=\"",name,"\")
RmdToHTML(file,paste0(\"results/Report_\",format(Sys.time(), \"%Y_%m_%d\"),\".html\"))
       
"),file="run.R")

  repoExists <- FALSE
  try({
    r <- git2r::repository(".")
    repoExists <- TRUE
  },TRUE)
  if(!repoExists){
    r <- git2r::init(".")
    message("* Adding files and committing")
    paths <- unlist(git2r::status(r, verbose = FALSE))
    git2r::add(r, paths)
    git2r::commit(r, "Initial commit")
  }
}

LoadPackage <- function(name="test"){
  packrat::on(name)
  
  packrat::set_opts(local.repos =paste0(getwd(),"/packages"))
  stat <- packrat::status()
  
  if(sum(is.na(stat$packrat.version))>0){
    packrat::snapshot()
    stat <- packrat::status()
  }
  if(sum(stat$packrat.version!=stat$library.version,na.rm=T)>0){
    packrat::restore()
  }
  
  try({
    r <- git2r::repository(".")
    r <- git2r::repository()
    paths <- unlist(git2r::status(r,verbose = FALSE))
    git2r::add(r, paths)
    git2r::commit(r, paste0("Committing while loading at ",Sys.time()))
  },TRUE)
  
  devtools::document(name)
  devtools::load_all(name)
}

# Copied from https://github.com/hadley/devtools/blob/master/R/dev-help.r
h <- function(topic, stage = "render", type = getOption("help_type")) {
  path <- devtools:::find_topic(topic)
  if (is.null(path)) {
    dev <- paste(devtools::dev_packages(), collapse = ", ")
    stop("Could not find topic ", topic, " in: ", dev)
  }

  pkg <- basename(names(path)[1])
  path <- normalizePath(path, winslash = "/")
    devtools:::view_rd(path, pkg, stage = stage, type = type)
}



