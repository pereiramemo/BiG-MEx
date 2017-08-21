# ufBGCtoolbox
ufBGCtoolbox consists of three modules designed for the mining of BGC domains and classes in metagenomic data.  
bgc_dom_annot: fast identification of BGC protein domains.  
bgc_dom_shannon: BGC domain-specific diversity estimation.  
bgc_model_class: BGC class relative count predictions.  

## Install

```
git clone git@github.com:pereiramemo/ufBGCtoolbox.git
```

## ufBGCtoolbox: bgc_dom_annot

See help
```
sudo ./run_bgc_dom_annot.bash . . --help
```

Run 
```
sudo ./run_bgc_dom_annot.bash \
  example/sim_meta_oms-1_redu_r1.fasta.gz\
  example/sim_meta_oms-1_redu_r1.fasta.gz \
  example/out_dom_annot \
  --intype dna \
  --nslots 4
```

## ufBGCtoolbox: bgc_dom_shannon

See help
```
sudo ./run_bgc_dom_shannon.bash . . . --help
```

> Usage: bgc_dom_shannon.bash <input file> <R1> <R2> <SR> <output directory> 
<options>

>  [-h] [-d|--domains CHAR] [-t|--nslots NUM] [-c|--coverage] [-p|--place_tree] 
 [-b|blast]

> -d, --domains   target domain names. Comma separeted list.
> -h, --help      print this help
> -b, --blast     run blast against reference database
> -c, --coverage  use coverage to compute diversity
> -p, --place_tree        place sequences in reference tree
> -t, --nslots    number of slots (default 2)



With Docker, all input files should be in the same directory

```
sudo mv example/out_dom_annot/pe_bgc_dom.gz example/
```
Run
```
sudo ./run_bgc_dom_shannon.bash \
  example/pe_bgc_dom.gz \
  example/sim_meta_oms-1_redu_r1.fasta.gz \
  example/sim_meta_oms-1_redu_r2.fasta.gz \
  example/out_dom_shannon \
  --blast \
  --place_tree \
  --coverage \
  --nslots 4 \
  --domains PKS_KS,PKS_AT
```

## ufBGCtoolbox: bgc_model_class

See help
```
sudo ./run_bgc_dom_shannon.bash . . --help
```

Run 
```
sudo ./run_bgc_class_models.bash \
  example/out_dom_annot/counts.tbl \
  example/out_class_models
```


