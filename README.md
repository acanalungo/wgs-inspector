# WGS Inspector

### **Requirements**

- OS: Linux or macOS
- Hardware: **at least 60GB** of free hard drive space for the VEP cache
- Packages:
  - Git (https://github.com/git-guides/install-git)
  - Docker (https://docs.docker.com/engine/install/)

### **Usage**

*On your host machine*
- Clone the repository: `git clone https://github.com/acanalungo/wgs-inspector.git`.
- Move your VCF file to the `user_data` directory of the repository.
- Run the container: `./run_container.sh` (this will pull the image if you haven't already).

*Inside the container*
- Download the VEP cache files to your machine by running: `./download_vep_cache.sh`. This will take a while,
  likely around 2-3 hours depending on your internet speed, as the compressed cache archive is ~25GB.
- Then run VEP on your data by running: `./run_vep.sh user_data/<vcf_filename> <sample_name>` with `<vcf_filename>`
  being the name of your file in the `user_data` directory, and `<sample_name>` being a more descriptive name of your
  choosing (e.g. your first name). On a sufficiently powerful machine -- one with 8 cores/16 threads or greater -- this
  step should finish in under an hour.
- When VEP is finished, you'll be left with an annotated VCF file called `vep_<sample_name>.vcf.gz`. To extract the
  relevant variants from this file, run the parser by running: `python3 annotation_parser.py user_data/vep_<sample_name>.vcf.gz`.
  Optionally, you can use the `--gnomad` and `--revel` flags to override the default cutoffs for the parser, which
  are 0.01 and 0.5, respectively. This step should finish in under ten minutes.
- The output of the parser will be a CSV file in the `user_data` directory containing all the variants matching the
  criteria, which you can open with any spreadsheet program and explore as you wish.

### **References**

Ensembl: https://doi.org/10.1093/nar/gkae1071

Ensembl VEP: https://doi.org/10.1186/s13059-016-0974-4

gnomAD: https://gnomad.broadinstitute.org

ClinVar: https://www.ncbi.nlm.nih.gov/clinvar

REVEL: https://doi.org/10.1016/j.ajhg.2016.08.016
