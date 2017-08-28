# ufBGCtoolbox
ufBGCtoolbox consists of three modules designed for the mining of BGC domains 
and classes in metagenomic data.  
1. bgc_dom_annot: fast identification of BGC protein domains.  
2. bgc_dom_shannon: BGC domain-specific diversity estimation.  
3. bgc_model_class: BGC class relative count predictions.  

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

Estimated diversities:

Index | PKS_KS | PKS_AT
---|---|---
Shannon | 3.299 | 4.172

PKS_KS subsampled distribution:

![distribution PKS_KS](https://github.com/pereiramemo/ufBGCtoolbox/blob/master/example/PKS_KS_div_est.png)

PKS_AT subsampled distribution:

![distribution PKS_AT](https://github.com/pereiramemo/ufBGCtoolbox/blob/master/example/PKS_AT_div_est.png)

To visualize the sequence placements the PKS_KS_placements_tree.pdf and PKS_AT_placements_tree.pdf images are generated:

Placed PKS_KS sequences
![tree PKS_KS](https://github.com/pereiramemo/ufBGCtoolbox/blob/master/example/PKS_KS_placements_tree.png)

Placed PKS_AT sequences
![tree PKS_AT](https://github.com/pereiramemo/ufBGCtoolbox/blob/master/example/PKS_AT_placements_tree.png)

## ufBGCtoolbox: bgc_model_class

See help
```
sudo ./run_bgc_class_models.bash . . --help
```

Run 
```
sudo ./run_bgc_class_models.bash \
  example/out_dom_annot/counts.tbl \
  example/out_class_models
```

Predicted abundances:

![barplot](https://github.com/pereiramemo/ufBGCtoolbox/blob/master/example/bgc_class_pred.png)
