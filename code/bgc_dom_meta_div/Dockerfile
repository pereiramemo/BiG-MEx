################################################################################
# bgc_dom_meta_div
################################################################################

FROM ubuntu:18.04

# ENV http_proxy http://webproxy.mpi-bremen.de:3128
# ENV https_proxy https://webproxy.mpi-bremen.de:3128
# ENV ftp_proxy ftp://webproxy.mpi-bremen.de:3128

################################################################################
# define env
################################################################################

ENV LD_LIBRARY_PATH=/usr/local/lib

RUN mkdir -p /bioinfo/software/
RUN mkdir -p /bioinfo/resources/
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
  zlib1g-dev \
  git \
  cmake \
  vim-common \
  python \
  software-properties-common 
  
RUN apt-get install -y \
  libcdk5-dev \
  libbz2-1.0 \
  libbz2-dev \
  liblzma-dev
 
RUN apt-get install -y rsync 

################################################################################
# install java    
################################################################################
 
RUN apt-get install -y openjdk-8-jdk  

################################################################################
# bbmap 
################################################################################

RUN cd /bioinfo/software/; \
  wget https://datapacket.dl.sourceforge.net/project/bbmap/BBMap_37.36.tar.gz; \
  tar xzfv BBMap_37.36.tar.gz

# output folder bbmap
  
################################################################################
# mmseqs2
################################################################################

RUN cd /bioinfo/software/; \
  git clone https://github.com/soedinglab/MMseqs2.git; \
  cd MMseqs2; \
  mkdir build; \
  cd build; \
  cmake -DCMAKE_BUILD_TYPE=RELEASE -DCMAKE_INSTALL_PREFIX=. ..; \
  make; \
  make install

# output folder MMseqs2  
  
################################################################################
# hmmer
################################################################################

RUN cd /bioinfo/software/; \
  wget http://eddylab.org/software/hmmer/hmmer-3.2.1.tar.gz; \
  tar xzfv hmmer-3.2.1.tar.gz; \
  cd hmmer-3.2.1; \
  ./configure; \
   make

RUN mv /bioinfo/software/hmmer-3.2.1 /bioinfo/software/hmmer
   
################################################################################
# bedtools2 
################################################################################

RUN cd /bioinfo/software/; \
  wget https://github.com/arq5x/bedtools2/releases/download/v2.28.0/\
bedtools-2.28.0.tar.gz; \
  tar -zxvf bedtools-2.28.0.tar.gz; \
  cd bedtools2; \
  make

# output folder bedtools2

################################################################################
# bwa
################################################################################

RUN cd /bioinfo/software/; \
  git clone https://github.com/lh3/bwa.git; \
  cd bwa; \
  make

# output folder bwa
  
################################################################################
# samtools
################################################################################

RUN cd /bioinfo/software/; \
  
wget https://github.com/samtools/samtools/releases/download/1.9/\
samtools-1.9.tar.bz2; \
tar xjfv samtools-1.9.tar.bz2; \ 
  cd samtools-1.9; \
  ./configure; \
  make

RUN mv /bioinfo/software/samtools-1.9 /bioinfo/software/samtools
  
################################################################################ 
# picard
################################################################################

RUN cd /bioinfo/software/; \
  wget https://github.com/broadinstitute/picard/releases/\
download/2.20.3/picard.jar

# output file picard.jar

################################################################################
# FragGeneScan
################################################################################

RUN cd  /bioinfo/; \
  wget https://netix.dl.sourceforge.net/project/fraggenescan/\
FragGeneScan1.31.tar.gz; \
  tar xzfv FragGeneScan1.31.tar.gz;
  
RUN mv /bioinfo/FragGeneScan1.31 /bioinfo/FragGeneScan

################################################################################
# mafft
################################################################################

RUN cd /bioinfo/software/; \
  wget https://mafft.cbrc.jp/alignment/software/\
mafft-7.429-with-extensions-src.tgz; \
  tar xzfv mafft-7.429-with-extensions-src.tgz; \
  cd mafft-7.429-with-extensions/core/; \
  make clean; \
  make; \
  make install;
  
RUN mv /bioinfo/software/mafft-7.429-with-extensions \ 
/bioinfo/software/mafft

################################################################################
# pplacer
################################################################################

RUN cd /bioinfo/software/; \
  wget https://github.com/matsen/pplacer/releases/download/\
v1.1.alpha19/pplacer-linux-v1.1.alpha19.zip; \
  unzip pplacer-linux-v1.1.alpha19.zip;
  
RUN mv /bioinfo/software/pplacer-Linux-v1.1.alpha19 /bioinfo/software/pplacer

################################################################################
# blast
################################################################################

RUN cd  /bioinfo/software/; \
  wget "ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/\
2.9.0/ncbi-blast-2.9.0+-x64-linux.tar.gz"; \
  tar xzfv ncbi-blast-2.9.0+-x64-linux.tar.gz

RUN mv "/bioinfo/software/ncbi-blast-2.9.0+" /bioinfo/software/blast  
  
################################################################################
# SPAdes
################################################################################
  
RUN cd /bioinfo/software/; \
  wget http://spades.bioinf.spbau.ru/release3.11.1/\
SPAdes-3.11.1-Linux.tar.gz; \
tar xzfv SPAdes-3.11.1-Linux.tar.gz;

RUN mv /bioinfo/software/SPAdes-3.11.1-Linux /bioinfo/software/SPAdes

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

RUN Rscript -e "install.packages('vegan')"
RUN Rscript -e "install.packages('BiocManager')"
RUN Rscript -e "BiocManager::install('ggtree');"

# tidyverse dependencies
RUN apt-get install -y libxml2-dev libcurl4-openssl-dev libssl-dev
RUN Rscript -e "install.packages('tidyverse')"

################################################################################
# clean (note: check if versions are correct)
################################################################################

RUN cd /bioinfo/software/; \
  rm BBMap_37.36.tar.gz \
     mafft-7.429-with-extensions-src.tgz \
     pplacer-linux-v1.1.alpha19.zip \
     ncbi-blast-2.9.0+-x64-linux.tar.gz \
     SPAdes-3.11.1-Linux.tar.gz \
     hmmer-3.2.1.tar.gz \
     samtools-1.9.tar.bz2 \
     bedtools-2.28.0.tar.gz
  
RUN cd /bioinfo/; \
 rm FragGeneScan1.31.tar.gz  

################################################################################
# copy modules
################################################################################
 
COPY resources/bgc_dom_meta_div.bash  /bioinfo/software/
RUN chmod +x /bioinfo/software/bgc_dom_meta_div.bash

COPY resources/modules/extract_assembly_cluster_and_place_wrap.bash \
/bioinfo/software/
RUN chmod +x /bioinfo/software/extract_assembly_cluster_and_place_wrap.bash

COPY resources/modules/coverage_compute.bash  /bioinfo/software/
RUN chmod +x /bioinfo/software/coverage_compute.bash

COPY resources/modules/tree_pplacer.bash /bioinfo/software/
RUN chmod +x /bioinfo/software/tree_pplacer.bash

COPY resources/modules/blast_runner.bash /bioinfo/software/
RUN chmod +x /bioinfo/software/blast_runner.bash

COPY resources/modules/tree_drawer.bash  /bioinfo/software/
RUN chmod +x /bioinfo/software/tree_drawer.bash

COPY resources/modules/sampled_div_est.bash  /bioinfo/software/
RUN chmod +x /bioinfo/software/sampled_div_est.bash

COPY resources/modules/mmseqs_runner.bash  /bioinfo/software/
RUN chmod +x /bioinfo/software/mmseqs_runner.bash

COPY resources/modules/create_cluster2abund_table.bash  /bioinfo/software/
RUN chmod +x /bioinfo/software/create_cluster2abund_table.bash

COPY resources/modules/extract_only_rep_seqs.bash  /bioinfo/software/
RUN chmod +x /bioinfo/software/extract_only_rep_seqs.bash

COPY resources/modules/model_div.R /bioinfo/software/
COPY resources/modules/model_div_plot.bash /bioinfo/software/
RUN chmod +x /bioinfo/software/model_div_plot.bash

COPY resources/conf /bioinfo/software/
COPY resources/handleoutput /bioinfo/software/
COPY resources/BGC_pHMMs/ /bioinfo/resources/BGC_pHMMs/
COPY resources/bgc_refpkgs/ /bioinfo/resources/bgc_refpkgs/
COPY resources/ref_seqs/ /bioinfo/resources/ref_seqs/

################################################################################
# workaround 
################################################################################

RUN sed -i 's/^mesg n.*/tty -s \&\& mesg n/g' /root/.profile

################################################################################
# permissions
################################################################################

RUN chmod -R a+rwX /scratch/
RUN chmod -R a+rwX /output/
RUN chmod -R a+rX /bioinfo/

RUN mkdir /bioinfo/FragGeneScan_workaround
RUN cp -r /bioinfo/FragGeneScan/ \
  /bioinfo/FragGeneScan_workaround

RUN chmod -R a+rX /bioinfo/FragGeneScan_workaround

################################################################################
# entry point
################################################################################

ENTRYPOINT ["/bioinfo/software/bgc_dom_meta_div.bash"]
