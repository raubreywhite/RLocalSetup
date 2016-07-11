docker run --rm \
 -v /media/FHI/Felles/Prosjekter/Dashboards/projects/X/:/src \
 -v /home/shiny/shinyapps_prod/log/data/:/log/ \
 dashboardsfhi/hadleyverse Rscript /src/Initialise.R

# -v /home/shiny/shinyapps_prod/X/:/app \
