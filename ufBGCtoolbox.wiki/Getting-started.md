# Getting started
## 0. Installing the toolbox
In case you haven't installed the toolbox yet, in GNU/Linux you can clone the repository in your place of choice, here we will suppose you are on the folder _Projects_ you already created on the first day. First, we will create a folder where we will run the tutorial:
```bash
mkdir -p ~/Projects/ufbgc_yourgroup/
cd ~/Projects/ufbgc_yourgroup
```
> Change **ufbgc_yourgroup** for the groups assigned on Sunday

Once we moved into the newly created folder we can clone the repository. This will download the necessary scripts to run the toolbox.
```bash
git clone git@github.com:pereiramemo/ufBGCtoolbox.git
cd ufBGCtoolbox
```
## 1. Gathering the data
In this example, we will run the ufBGCtoolbox to analyze three different metagenomic samples of the [Ocean Sampling Day campaign 2014](https://mb3is.megx.net/osd-registry): OSD2, 3 and 4.

First, we are going to download the [workable](https://github.com/MicroB3-IS/osd-analysis/wiki/Guide-to-OSD-2014-data) merged and unmerged sequence data from the OSD2014.

```bash
URL="https://owncloud.mpi-bremen.de/index.php/s/RDB4Jo0PAayg3qx/download?path=\
%2F2014%2Fdatasets%2Fworkable%2Fmetagenomes%2F"

BIN="$(greadlink -m ~/Projects/ufbgc_yourgroup/ufBGCtoolbox)"

OUTPUT_DIR="$(greadlink -m ~/Projects/ufbgc_yourgroup/ufBGCtoolbox/tutorial/OSD_data/)"

mkdir -p "${OUTPUT_DIR}"

SAMPLES=$(seq -s" " 2 4)

for i in $( echo "${SAMPLES}" ); do  
 curl -o "${OUTPUT_DIR}/OSD${i}_ME_shotgun_workable_merged.fastq.gz" \
 "${URL}merged&files=OSD${i}_ME_shotgun_workable_merged.fastq.gz"

  curl -o "${OUTPUT_DIR}/OSD${i}_SE_shotgun_workable_merged.fastq.gz" \
  "${URL}merged&files=OSD${i}_SE_shotgun_workable_merged.fastq.gz"
  
  curl -o "${OUTPUT_DIR}/OSD${i}_R1_shotgun_workable.fastq.gz" \
  "${URL}non-merged&files=OSD${i}_R1_shotgun_workable.fastq.gz"  

  curl -o "${OUTPUT_DIR}/OSD${i}_R2_shotgun_workable.fastq.gz" \
  "${URL}non-merged&files=OSD${i}_R2_shotgun_workable.fastq.gz"
done
```
Once we have the data, we concatenate the unmerged (SE) and the merged (ME) sequences.

```bash
for i in $( echo "${SAMPLES}" ); do
  cat "${OUTPUT_DIR}/OSD${i}_ME_shotgun_workable_merged.fastq.gz" \
  "${OUTPUT_DIR}/OSD${i}_SE_shotgun_workable_merged.fastq.gz" > \
  "${OUTPUT_DIR}/OSD${i}_ME_n_SE_shotgun_workable_merged.fastq.gz"

  rm "${OUTPUT_DIR}/OSD${i}_ME_shotgun_workable_merged.fastq.gz" \
  "${OUTPUT_DIR}/OSD${i}_SE_shotgun_workable_merged.fastq.gz"
done
```

## 2. Indentifying the BGC domains
To identify the BGC forming domains, the uf-BGC-toolbox, uses [UProC](http://uproc.gobics.de/) 1.2.0 software (Meinicke, 2014) to classify short-read sequences into BGC domains. UProC has been trained with a manually curated amino acid sequences of 150 antiSMASH hidden Markov model profiles (HMMs) (Weber et al., 2015). The module in ufBGCtoolbox in charge to the domain identification is the **bgc_dom_annot**. The toolbox has a convenient wrapper (**run_bgc_dom_annot.bash**) to call this module through the docker image:

```bash
for i in $( echo "${SAMPLES}" ); do
  printf "Detecting domains in OSD${i}...\n"
  sudo "${BIN}/run_bgc_dom_annot.bash" \
  "${OUTPUT_DIR}/OSD${i}_ME_n_SE_shotgun_workable_merged.fastq.gz" \
  "${OUTPUT_DIR}/out_dom_annot_osd${i}" \
  --intype dna \
  --nslots 8 \
  --sample "osd${i}"
  done
```
After running the domain annotation you will have the results in **tutorial/OSD_data/out_dom_annot_osd2**, **tutorial/OSD_data/out_dom_annot_osd3** and **tutorial/OSD_data/out_dom_annot_osd4**. Inside of each folder, we will find the files **se_bgc_dom.gz**, **counts.tbl** and **class2domains2abund.tbl** that contain the domain annotations of the reads and the counts and their associated BGC classes. Let's have a look at the contents of the **class2domains2abund.tbl** file with _head_:
```bash
head OSD_data/out_dom_annot_osd2/class2domains2abund.tbl
```
First column is our sample, second column is the BGC class, third column the domain and the fourth column shows the counts:
```
osd2  bacteriocin DUF692  8
osd2  bacteriocin TIGR03798 1
osd2  cf_fatty_acid fabH  289
osd2  cf_fatty_acid ft1fas  1
osd2  cf_fatty_acid t2fas 718
osd2  cf_saccharide Glycos_transf_1 905
osd2  cf_saccharide Glycos_transf_2 1492
```

## 3. Assessing domain diversity in our samples

One interesting question to address when analyzing BGCs, is what is the domain diversity in our samples. Samples with a higher diversity might harbor interesting variants with slightly different properties of the BGC classes we are interested. The toolbox includes a module to compute the domain-specific diversity, based on the domain annotation. The analysis consists of the following steps: 

1. Annotated reads are used to construct a targeted assembly of the domains using metaSPAdes 3.11 (Nurk et al., 2013) with default parameters.
2. Open Reading Frames (ORFs) are predicted on the resulting contigs with FragGeneScan 1.19 (Rho, Tang, & Ye, 2010).
3. Domain sequences are identified within the ORF amino acid sequences with hmmsearch from HMMER v3 (Eddy, 2011).
4. Domain nucleotide and amino acid sequences (hereafter DNS and DAAS, respectively) are extracted.
5. DAAS are clustered using MMseqs2 (Hauser, Steinegger, & Söding, 2016) with an identity threshold of 0.7, the cascaded clustering option and the sensitivity parameter set to 7.5. We will refer to these clusters as operational domain units (ODUs).
6. Annotated unassembled reads are mapped on the DNS with BWA-MEM 0.7.12 (Li, 2013) and the sequence coverage is estimated. 
7. Based on this information, the abundance of the ODUs is computed and used to calculate the Shannon diversity index.

In addition to the diversity of the domains, we would also like to know how different are the domains identified in comparison to the reference domains present in the [MIBiG](https://mibig.secondarymetabolites.org/) database. To answer this question, the toolbox includes a workflow where the assembled domains are placed in reference trees based on 65 reference domains. The pipeline does:

1. Phylogenetic placements are performed by aligning a target metagenomic assembled domain to its reference MSA with MAFFT (using --add option)(Yamada, Tomii, & Katoh, 2016).
2. Subsequently, this extended MSA together with its corresponding reference tree, are used as the input to run pplacer (F. A. Matsen, Kodner, & Armbrust, 2010), which generates the phylogenetic placements.

As an example for the tutorial we will explore the **acyltransferase** (PKS_AT) and the **keto-synthase** (PKS_KS) domains from the [**Polyketide synthase**](https://en.wikipedia.org/wiki/Polyketide_synthase) BGC class. From Wikipedia (not the best source though):

> Polyketide synthases are an important source of naturally occurring small molecules used for chemotherapy.[3] For example, many of the commonly used antibiotics, such as tetracycline and macrolides, are produced by polyketide synthases. Other industrially important polyketides are sirolimus (immunosuppressant), erythromycin (antibiotic), lovastatin (anticholesterol drug), and epothilone B (anticancer drug).

> Only about 1% of all known molecules are natural products, yet it has been recognized that almost two thirds of all drugs currently in use are at least in part derived from a natural source. This bias is commonly explained with the argument that natural products have co-evolved in the environment for long time periods and have therefore been pre-selected for active structures. Polyketide synthase products include lipids with antibiotic, antifungal, antitumor, and predator-defense properties; however, many of the polyketide synthase pathways that bacteria, fungi and plants commonly use have not yet been characterized. Methods for the detection of novel polyketide synthase pathways in the environment have therefore been developed. Molecular evidence supports the notion that many novel polyketides remain to be discovered from bacterial sources.  

Polyketide synthases look like a nice target to look in our metagenomes. The module from the toolbox to calculate the diversity and perform the phylogenetic placement is **bgc_dom_div** nicely wrapped in the docker image under the script **run_bgc_dom_div.bash**

We will add the sample name to the  **se_bgc_dom.gz** (Uproc output) file from each study (it will result as **se_bgc_dom_osd1.gz**), and we will move it to the working directory, given that we are using Docker, all input files must be in the same directory.

```bash
for i in $( echo "${SAMPLES}" ); do
  mv "${OUTPUT_DIR}/out_dom_annot_osd${i}"/se_bgc_dom.gz \
  "${OUTPUT_DIR}/se_bgc_dom_osd${i}".gz
done
```

Now we can run the wrapper of **bgc_dom_div** in **sample** mode as follows:

```bash
for i in $( echo "${SAMPLES}" ); do
  sudo "${BIN}/run_bgc_dom_div.bash" sample \
  "${OUTPUT_DIR}/se_bgc_dom_osd${i}".gz \
  "${OUTPUT_DIR}/OSD${i}_R1_shotgun_workable.fastq.gz" \
  "${OUTPUT_DIR}/OSD${i}_R2_shotgun_workable.fastq.gz" \
  "${OUTPUT_DIR}/out_dom_div_osd${i}" \
  --blast t \
  --identity 0.5 \
  --plot_tree t \
  --only_rep t \
  --coverage t \
  --nslots 8 \
  --verbose t \
  --domains PKS_KS,PKS_AT 2>&1 | tee bgc_dom_div_sample_osd${i}.log
done
```
> Running **run_bgc_dom_div.bash** with `--verbose t` will produce a lot of output on your screen, you can capture it with **tee** `| tee bgc_dom_div_sample_osd${i}.log`. Tee will show the output on the screen while saving it on a file.

If you run the command `./run_bgc_dom_div.bash sample . . . --help` You will have a brief explanation of all parameters used. To save you time, here there are some of the most important parameters used in the command:

- **--blast**: This will tell the module to blast the assembled domains against the references
- **--identity**: The clustering minimum identity (default 0.7) used by MMseqs
- **--plot_tree**: Place sequences in reference tree and plot the resulting tree
- **--only_rep**: Use only representative cluster sequences in tree placement
- **--coverage**: Use coverage to compute diversity
- **--domains**: Target domain names as a comma separated list
- **--nslots**: Number of cores for metaSPAdes, FragGeneScan, hmmsearch, mmseqs cluster, bwa mem and samtools

The workflow generates many files as output. These are found under **tutorial/OSD_data/out_dom_div_osd2**, **tutorial/OSD_data/out_dom_div_osd3** and **tutorial/OSD_data/out_dom_div_osd4**. Inside these folders there is also the output of the phylogenetic placement under **tutorial/OSD_data/out_dom_div_osd2/PKS_AT_tree_data** for the PKS_AT domains or **tutorial/OSD_data/out_dom_div_osd2/PKS_KS_tree_data** for the PKS_KS. We will use **tutorial/OSD_data/out_dom_div_osd2** as an example. Interesting files/folders to look inside this folder are:

- **PKS_KS_cluster2abund.tsv**: This file contains the coverage calculated for each assembled domain
- **PKS_KS_summary_model_div_est.tsv**: This file contains the diversity estimates after running 100 iterations, in a real example use at least 500
- **PKS_AT_violin_div_est.pdf**: The distribution of the values in the diversity estimation, this can give us an idea of our randomizations and possible biases in the estimates.
-**PKS_AT_tree_data/PKS_AT_placements_tree.pdf**: A plot with the placed assembled domains in the PKS_AT reference tree

Let's explore some of the files... you can copy your files in the VM to your local machine with `scp` or `rsync`. To make your life easier here there is the output of some of them... Let's have a look to the estimated diversities file with:
```bash
cat OSD_data/out_dom_div_osd2/PKS_KS_summary_model_div_est.tsv
```
| |value|
|:---:|:----:|
|diversity|1.908|
|mean|1.51|
|sd|0.459|

And the plots of the placements look like:  

<p align="center">
<b>Placed PKS_KS sequences from sample OSD2</b><a href="https://github.com/pereiramemo/ufBGCtoolbox/blob/master/example/PKS_KS_placements_tree_large_osd2.png"> [Large image]</a> 
<img src="https://github.com/pereiramemo/ufBGCtoolbox/blob/master/example/PKS_KS_placements_tree_small_osd2.png">
</p>

<p align="center">
<b>Placed PKS_AT sequences from sample OSD2</b><a href="https://github.com/pereiramemo/ufBGCtoolbox/blob/master/example/PKS_AT_placements_tree_large_osd2.png"> [Large image]</a> 
<img src="https://github.com/pereiramemo/ufBGCtoolbox/blob/master/example/PKS_AT_placements_tree_small_osd2.png">
</p>

We can explore our log files to gather extra information (we need to implement a better way), for example if we do:
```bash 
grep 'Not enough' bgc_dom_div_sample_osd*.log
```
we will learn that there are not enough PKS_KS sequences in sample OSD4 to perform the analysis.  
> bgc_dom_div_sample_osd4.log:Not enough PKS_KS sequences found: 1

Now the results are split by sample, this can be useful to answer certain questions, but being able the combine multiple samples will help us to get a better understanding of what's going on in our set of metagenomes. We can use the generated output by the __sample__ mode and merge our results with the wrapper of **bgc_dom_div** in **merge** mode as follows. First for the PKS_KS domain:

```bash
sudo "${BIN}/run_bgc_dom_div.bash" merge \
"${OUTPUT_DIR}/out_dom_div_osd2","${OUTPUT_DIR}/out_dom_div_osd3" \
"${OUTPUT_DIR}/out_dom_merged_div_osd_PKS_KS" \
--domain PKS_KS \
--num_iter 50 \
--sample_increment 20 \
--plot_rare_curve t \
--plot_tree t \
--only_rep t \
--nslots 2 \
--verbose t 2>&1 | tee bgc_dom_div_merge_PKS_KS.log
```
And for the PKS_AT domain:
```bash
sudo "${BIN}/run_bgc_dom_div.bash" merge \
"${OUTPUT_DIR}/out_dom_div_osd2","${OUTPUT_DIR}/out_dom_div_osd3",\
"${OUTPUT_DIR}/out_dom_div_osd4" \
"${OUTPUT_DIR}/out_dom_merged_div_osd_PKS_AT" \
--domain PKS_AT \
--num_iter 50 \
--sample_increment 20 \
--plot_rare_curve t \
--plot_tree t \
--only_rep t \
--nslots 2 \
--verbose t 2>&1 | tee bgc_dom_div_merge_PKS_AT.log
```

Let's have a look at the generated new files by the **merge** module for the PKS_AT domain. Now the estimated diversities file contains:
```bash
cat OSD_DATA/out_dom_merged_div_osd_PKS_AT/out_dom_merged_div_osd_PKS_AT/PKS_AT_summary_model_div_est.tsv
```

|sample_id|mean|sd|
|:----:|:----:|:----:|
out_dom_div_osd2|2.85108486443565|0.469641314300697
out_dom_div_osd3|2.66396614956598|0.502680334561416
out_dom_div_osd4|2.61976370188556|0.489710021233121


To compare the domain diversity between samples, we have the rarefaction plot `OSD_DATA/out_dom_merged_div_osd_PKS_AT/PKS_AT_rare_div_est.pdf`

<p align="center">
<b>Diversity rarefaction plot <img src="https://github.com/pereiramemo/ufBGCtoolbox/blob/master/example/PKS_AT_placements_tree.png">
</p>




It may be useful to analyze the phylogenteic placement of all the samples togehter. You can find this integrated placement under `OSD_DATA/out_dom_merged_div_osd_PKS_AT/PKS_AT_tree_data/`, including the tree plot.

<p align="center">
<b>Placed PKS_AT sequences from all samples </b><a href="https://github.com/pereiramemo/ufBGCtoolbox/blob/master/example/PKS_AT_placements_tree.pdf"> [Large image]</a> 
<img src="https://github.com/pereiramemo/ufBGCtoolbox/blob/master/example/PKS_AT_placements_tree.png">
</p>



## 4. run the BCG class model predictions: bgc_model_class  

Note: The predictions are based on the bgc domain annotation
```bash
for i in $( echo "${SAMPLES}" ); do

sudo "${BIN}/run_bgc_class_models.bash" \
  "${OUTPUT_DIR}/out_dom_annot_osd${i}/counts.tbl" \
   "${OUTPUT_DIR}/out_class_pred_osd${i}" \
   --verbose t
   
done

```

Predicted abundances :

OSD2

https://raw.githubusercontent.com/wiki/pereiramemo/ufBGCtoolbox/

![barplot2](https://github.com/pereiramemo/ufBGCtoolbox/blob/master/example/bgc_class_pred_osd2.png)

OSD3

![barplot3](https://github.com/pereiramemo/ufBGCtoolbox/blob/master/example/bgc_class_pred_osd3.png)

OSD4

![barplot4](https://github.com/pereiramemo/ufBGCtoolbox/blob/master/example/bgc_class_pred_osd4.png)
