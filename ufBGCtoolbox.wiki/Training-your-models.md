To train a BGC class relative counts (RCs) model we use simulated metagenomic data. This allows us to estimate with relative precision the BGC class RCs, and "learn" how these relate to the BGC domain RCs, estimated from the annotation of unassembled metagenomic data. Each model is trained by using the BGC class RCs as the response variable and its domain RCs as predictor variables.

Although we only provide BGC class RC models designed for the mining of marine environments, we will be uploading models to screen metagenomes from other types of environments in the near future. We provide, however, the code to simulate the metagenomic data, and train the BGC class RC models. By simulating metagenomes with the appropriate taxonomic profiles, users can customize the models for the mining of BGC classes in any type environment.

* [**Here**](https://github.com/pereiramemo/ufBGCtoolbox/wiki/Data-simulation) there is a workflow to generate the simulated the BGC domain and class abundances.

* [**Here**](https://rawgit.com/pereiramemo/ufBGCtoolbox/master/machine_leaRning/bgcpred_workflow.html) there is a step-by-step tutorial of how to train your models with [**bgcpred**](https://github.com/pereiramemo/bgcpred).


