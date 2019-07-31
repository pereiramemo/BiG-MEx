################################################################################
# bgc_class_pred
################################################################################

FROM ubuntu:18.04

################################################################################
# define env
################################################################################

ENV LD_LIBRARY_PATH=/usr/local/lib

RUN mkdir -p /bioinfo/software/
RUN mkdir -p /bioinfo/resources/
RUN mkdir -p /output/
RUN mkdir -p /input/
RUN mkdir -p /scratch/

#ENV http_proxy http://webproxy.mpi-bremen.de:3128
#ENV https_proxy https://webproxy.mpi-bremen.de:3128
#ENV ftp_proxy ftp://webproxy.mpi-bremen.de:3128

################################################################################
# get basic packages
################################################################################

RUN apt-get update
RUN apt-get install -y apt-utils 

RUN apt-get install -y \
  wget \
  zip \
  unzip \
  build-essential \
  joe \
  less \
  zlib1g-dev 
  
RUN apt-get install -y \  
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev
     

RUN apt-get install -y rsync

RUN apt-get install -y --allow-unauthenticated --fix-missing \
     software-properties-common 
 
RUN apt-get install -y --allow-unauthenticated --fix-missing \
    apt-transport-https

################################################################################
# R
################################################################################

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys \
E298A3A825C0D65DFD57CBB651716619E084DAB9 
RUN add-apt-repository 'deb [arch=amd64,i386] \
https://cloud.r-project.org/bin/linux/ubuntu bionic-cran35/'
   
ENV TZ=Europe/Paris
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update
RUN apt-get install -y r-base

RUN echo "r <- getOption('repos'); \
r['CRAN'] <- 'http://cran.us.r-project.org'; options(repos = r);" > ~/.Rprofile

RUN Rscript -e "install.packages('tidyverse')"

RUN Rscript -e "install.packages('devtools')"
    
RUN Rscript -e "devtools::install_github('pereiramemo/bgcpred')"

################################################################################
# copy files
################################################################################

COPY resources/bgc_class_pred.bash /bioinfo/software/
RUN chmod 777 /bioinfo/software/bgc_class_pred.bash
COPY resources/conf /bioinfo/software/
COPY resources/handleoutput /bioinfo/software/
 
################################################################################
# workaround 
################################################################################
 
RUN sed -i 's/^mesg n.*/tty -s \&\& mesg n/g' /root/.profile

################################################################################
# permissions
################################################################################

RUN chmod -R 777 /scratch/
RUN chmod -R 777 /output/
# RUN chmod -R 777 /bioinfo/software/
RUN chmod -R 777 /bioinfo/
RUN chmod -R 777 /input/

################################################################################
# entry point
################################################################################

ENTRYPOINT ["/bioinfo/software/bgc_class_pred.bash"]



    
