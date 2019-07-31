################################################################################
# BGC domains annotation
################################################################################

FROM ubuntu:18.04

#ENV http_proxy http://webproxy.mpi-bremen.de:3128
#ENV https_proxy https://webproxy.mpi-bremen.de:3128
#ENV ftp_proxy ftp://webproxy.mpi-bremen.de:3128

################################################################################
# define env
################################################################################

ENV LD_LIBRARY_PATH=/usr/local/lib

RUN mkdir -p /bioinfo/software/
RUN mkdir -p /output/
RUN mkdir -p /input/
RUN mkdir -p /scratch/

################################################################################
# get basic packages
################################################################################

RUN apt-get update && apt-get install -y apt-utils 

RUN apt-get install -y \
  wget \
  zip \
  unzip \
  build-essential \
  joe \
  less \
  zlib1g-dev
  
RUN apt-get install -y rsync  

################################################################################
# uproc
################################################################################

RUN wget http://uproc.gobics.de/downloads/uproc/uproc-1.2.0.tar.gz
RUN tar xzfv uproc-1.2.0.tar.gz -C /bioinfo/software/ 

RUN  cd  /bioinfo/software/uproc-1.2.0/; \
  ./configure; \
  make; \
  make install
 
################################################################################
# clean
################################################################################

RUN rm uproc-1.2.0.tar.gz

################################################################################
# permissions
################################################################################

RUN chmod -R 777 /scratch/
RUN chmod -R 777 /output/
RUN chmod -R 777 /bioinfo/
#RUN chmod -R 777 /bioinfo/software/
RUN chmod -R 777 /input/

################################################################################
# copy files
################################################################################

COPY resources/bgc_dom_annot.bash /bioinfo/software/
RUN chmod 777 /bioinfo/software/bgc_dom_annot.bash

COPY resources/conf /bioinfo/software/
COPY resources/handleoutput /bioinfo/software/
COPY resources/class2domains.list /bioinfo/software/
COPY resources/bgc13062014 /bioinfo/software/bgc13062014
COPY resources/model /bioinfo/software/model

################################################################################
# workaround
################################################################################

RUN sed -i 's/^mesg n.*/tty -s \&\& mesg n/g' /root/.profile

################################################################################
# entry point
################################################################################

ENTRYPOINT ["/bioinfo/software/bgc_dom_annot.bash"]
 
