# BiG-MEx
## Repository under construction. Links and tools might not work as expected or not work at all.


BiG-MEx: a tool for the mining of Biosynthetic Gene Cluster (BGC) domains and classes in metagenomic data. It consists of the following modules:
1. run_bgc_profiler: BGC protein domains annotation and BGC class abundance predictions  
2. run_bgc_dom_div: BGC domain-based diversity analysis.  

## Citation
Pereira-Flores, E., Buttigieg, P. L., Medema, M. H., Meinicke, P., Glöckner, F. O. and Fernandez-Guerra, A.. (2021). _Mining metagenomes for natural product biosynthetic gene clusters: unlocking new potential with ultrafast techniques_. bioRxiv doi: 10.1101/2021.01.20.427441

## Installation
BiG-MEx consists of three container images (docker or singularity): 
1. bgc_profiler  
2. bgc_dom_meta_div  
3. bgc_dom_merge_div  

Before running BiG-MEx it is necessary to install either [docker](https://www.docker.com/) or [singularity](https://sylabs.io/).
Then simply download the scripts from below:
```
Using docker container images:
run_bgc_profiler_doc.bash
run_bgc_dom_div_doc.bash

Using singularity container images:
run_bgc_profiler_sif.bash
run_bgc_dom_div_sif.bash

git clone https://github.com/pereiramemo/BiG-MEx.git
```
All conatiner images will be downloaded automatically the first time you run the scripts.

## Documentation
The run_bgc_\*.bash scripts run the container images, which include all the code, dependencies, and data used in the analysis. 
When using [docker](https://www.docker.com/), if your user is not in the [docker group](https://docs.docker.com/engine/installation/linux/linux-postinstall/#manage-docker-as-a-non-root-user) in Linux or Mac OS, the run_bgc_\*.bash scripts have to be executed with sudo.

### 1. bgc_profiler
This module first runs [UProC](http://uproc.gobics.de/) using a BGC domain database. It takes as an input metagenomic unassembled data and outputs the BGC domain counts profile. Then, based on the [bgcpred](https://github.com/pereiramemo/bgcpred) R package and using the BGC domains as predictor variables, it computes the BGC class abundance profile.

See help
```
./run_bgc_profiler.bash . . --help
```

### 2. bgc_dom_div

The **bgc_dom_div** has two different modes: metagenome (meta), and merge. The first mode has the objective of analyzing the BGC domain diversity in metagenomic samples. The diversity analysis consists of estimating the operational domain unit (ODU) diversity, blasting the domain sequences against a reference database, and placing the domain sequences onto reference trees.
The merge mode integrates the metagenome diversity results of different samples to provide a comparative analysis.

See help
```
./run_bgc_dom_div.bash meta . . . --help

./run_bgc_dom_div.bash merge . .  --help
```

### See the [wiki](https://github.com/pereiramemo/BiG-MEx/wiki) for further documentation.
