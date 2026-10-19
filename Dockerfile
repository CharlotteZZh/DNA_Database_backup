# MethylProphet DB - Shiny app image for the Duke Kubernetes Service (DKSO / OpenShift)

FROM rocker/r-ver:4.6.1

# R packages used by app.R and pages/
RUN install2.r --error --skipinstalled \
      shiny \
      bslib \
      plotly \
      DT \
    && rm -rf /tmp/downloaded_packages

WORKDIR /app
COPY . /app

# OpenShift runs containers as a random non-root UID in group 0,
# so group 0 needs the same permissions as the owner.
RUN chgrp -R 0 /app && chmod -R g=u /app

ENV HOME=/tmp
USER 1001

EXPOSE 3838

CMD ["Rscript", "-e", "shiny::runApp('/app', host = '0.0.0.0', port = 3838, launch.browser = FALSE)"]
