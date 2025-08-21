# WGS Inspector



The general idea here is to downsample from the approximately 5 million variants -- positions where your genotype *varies*
from the reference -- in your genome to around 1,000 variants which are most likely to be relevant to your health, ideally
something you could look through in a day or two. Of course, such a simplification will always miss something, but I think
this represents the minimal amount of time and effort invested to glean most of the interesting insights based on the best 
available data. After you've downloaded the necessary cache data (~3 hours depending on internet speed), you should be 
able to process an entire genome's worth of information in around an hour; the whole ordeal should be doable in an
afternoon.

This tool currently handles only genomic data from Variant Call Format (VCF) files, as that is the most efficient way to
transmit and analyze the information. It will not work with sequence data formats like SAM, BAM, CRAM, FASTQ, or FASTA.

*DISCLAIMER: I am not a doctor and the output of the tool should not be considered to be medical advice. This is for 
educational and recreational purposes only.*

### **Supported WGS Providers**

This tool has been tested extensively on data from the following WGS providers:
- Sequencing.com (https://sequencing.com)
- Nebula Genomics (https://nebula.org)
- Nucleus Genomics (https://mynucleus.com)

If you have a VCF file from another provider, everything **should** still work just fine, but there can be subtle differences in
how labs process their data which could lead to unexpected issues. The above three are the only ones I've tested and
confirmed to run smoothly.

### **Requirements**

- OS: Linux, macOS, or Windows (with WSL or Docker Desktop)
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
