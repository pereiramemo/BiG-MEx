Currently, we provide a general model and two environment-specific models (more to come in the future).

Note: You can use any of these models with run_bgc_class_pred. Assuming you already created the out_dom_annot/counts.tbl file:
```
./run_bgc_class_pred.bash \
out_dom_annot/counts.tbl \
General_model.RData out_class_pred \
--overwrite t \
--verbose t

```

#### Environment-specific models:
1) General models. Reference taxonomy: random sampling from [RefSeq database](https://www.ncbi.nlm.nih.gov/refseq/). [Download](https://github.com/pereiramemo/BiGMEx/wiki/files/General_model.RData) and [cross validation analysis](https://pereiramemo.shinyapps.io/shiny_app_general_cv/)
2) Mairine models. Reference taxonomy: [Ocean Microbial Reference Gene Catalog (OM-RGC)](http://ocean-microbiome.embl.de/companion.html). [Download](https://github.com/pereiramemo/BiGMEx/wiki/files/OMs_model.RData) and [cross validation analysis](https://pereiramemo.shinyapps.io/shiny_app_oms_cv/)
3) Infant gut microbiome models. Reference taxonomy: [Sharon et al., 2013](https://ggkbase.berkeley.edu/carrol/organisms). [Download](https://github.com/pereiramemo/BiGMEx/wiki/files/IGD_model.RData) and [cross validation analysis](https://pereiramemo.shinyapps.io/shiny_app_igd_cv/)
4) Human gastrointestinal tract models. Reference taxonomy: [HMP](https://hmpdacc.org/) genome sequences. [Download](https://github.com/pereiramemo/BiGMEx/wiki/files/HMP_GIT_model.RData) and [cross validation analysis](https://pereiramemo.shinyapps.io/shiny_app_HMP_GIT_CV/)
5) Human oral tract models. Reference taxonomy: [HMP](https://hmpdacc.org/) genome sequences. [Download](https://github.com/pereiramemo/BiGMEx/wiki/files/HMP_ORAL_model.RData) and [cross validation analysis](https://pereiramemo.shinyapps.io/shiny_hmp_oral_cv/)
6) Human urogenital tract models. Reference taxonomy: [HMP](https://hmpdacc.org/) genome sequences. [Download](https://github.com/pereiramemo/BiGMEx/wiki/files/HMP_UGT_model.RData) and [cross validation analysis](https://pereiramemo.shinyapps.io/shiny_hmp_ugt_cv/)

#### Taxon-specific models:
1) Streptomyces models. Reference genomes taken from [RefSeq database](https://www.ncbi.nlm.nih.gov/refseq/). [Download](https://github.com/pereiramemo/BiGMEx/wiki/files/Streptomyces_model.RData) and [cross validation analysis](https://pereiramemo.shinyapps.io/shiny_app_streptomyces_cv/)
