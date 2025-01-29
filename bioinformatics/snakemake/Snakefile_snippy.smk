configfile:
	"configJL.yaml"
R1_suff = config['R1_suffix']
R2_suff = config['R2_suffix']
print("Read directory: " + config['reads'])
print("Read suffixes: " + R1_suff + ", " + R2_suff)
sample_ids, = glob_wildcards("data/{sample}_1.fastq.gz")
outputdir = config['output']
print("Found sample IDs: ", sample_ids)

rule all: 
    input:
        expand("{outputdir}/snps_out/{sample}_snps", sample=sample_ids, outputdir=outputdir)

rule snippy:
    input:
        reference = "Reference.fasta",
        r1 = config['reads']+"/{sample}"+R1_suff,
        r2 = config['reads']+"/{sample}"+R2_suff
    output:
        directory("{outputdir}/snps_out/{sample}_snps")
    log:
        "{outputdir}/{sample}_snippy.log"
    shell:
        "snippy --outdir {output} --ref {input.reference} --R1 {input.r1} --R2 {input.r2} > {log} 2>&1"
