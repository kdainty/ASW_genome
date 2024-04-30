#!/usr/bin/env python3


#pipeline to try multiple assemblers, then trycycler




###############
# CONTAINERS ## 
###############



flye_container = 'docker://nanozoo/flye:2.9.3--973d045'
busco_container = 'docker://nanozoo/busco:5.5.0--427a3e7'
unicycler_container = 'docker://staphb/unicycler:0.5.0'
raven_container = 'docker://staphb/raven:1.8.3'
wtdbg2_container = 'docker://staphb/wtdbg2:2.5'
minimap2_container = 'docker://nanozoo/minimap2:2.26--d9ef6b6'
miniasm_container = 'docker://biocontainers/miniasm:v0.2dfsg-2b1-deb_cv1'
minipolish_container = 'docker://staphb/minipolish:0.1.3'
quast_container = 'docker://staphb/quast:5.2.0'
nextdenovo_container = 'docker://kandinge/nextdenovo:2.5.2'





#########
# RULES #
#########


rule target:
	input:
		expand('/Volumes/archive/deardenlab/kimdainty/ASW_genome/output/{assemblies}/busco/short_summary.specific.endopterygota_odb10.busco.txt', 
				assemblies=["flye_assembly_new", "unicycler_assembly", "wtdg2_assembly", "nextdenovo_assembly", "masurca_assembly"]),
		'/Volumes/archive/deardenlab/kimdainty/ASW_genome/output/quast/report.txt'



#######
# QCs #
#######



rule quast:
	input:
		assemblies = expand('/Volumes/archive/deardenlab/kimdainty/ASW_genome/output/{assemblies}/assembly.fasta', assemblies=["flye_assembly_new", "unicycler_assembly", "wtdg2_assembly", "nextdenovo_assembly", "masurca_assembly"]),
		reads = '/Volumes/archive/deardenlab/kimdainty/ASW_genome/dorado_basecalled/ASW_dorado_0.5.3_duplex_basecalls.fastq'
	output:
		'/Volumes/archive/deardenlab/kimdainty/ASW_genome/output/quast/report.txt'
	params:
		wd = '/Volumes/archive/deardenlab/kimdainty/ASW_genome/output/quast/'
	threads:
		40
	log:
		'/Volumes/archive/deardenlab/kimdainty/ASW_genome/output/logs/quast.log'
	singularity:
		quast_container
	shell:
		'quast.py '
		'-o {params.wd} '
		#"--min-contig # " #this default is 500
		'--threads {threads} '
		'-L ' #uses assembly names from parent diretory
		'--eukaryote ' #uses GeneMark-ES not GeneMarkS and other things
		'--large ' #use for larger than 100 Mbp
		'--circos '
		'--nanopore {input.reads} '
		'2> {log} '
		'{input.assemblies}'





rule busco:
	input:
		'/Volumes/archive/deardenlab/kimdainty/ASW_genome/output/{assemblies}/assembly.fasta'
	output:
		'/Volumes/archive/deardenlab/kimdainty/ASW_genome/output/{assemblies}/busco/short_summary.specific.endopterygota_odb10.busco.txt'
	threads:
		40
	params:
		wd = '/Volumes/archive/deardenlab/kimdainty/ASW_genome/output/{assemblies}/'
	log:
		'/Volumes/archive/deardenlab/kimdainty/ASW_genome/output/logs/{assemblies}_busco.log'
	singularity:
		busco_container
	shell:
		'cd {params.wd} || exit 1 ; '
		'busco '
		'-i {input} '
		'-m genome '
		'-l endopterygota_odb10 '
		'-c {threads} '
		'-f '
		'-o busco '
		'2> {log}'


#longstitch
#goldrush
#quast to compare assemblies
#Raft
#pecat




#############
# trycycler #
#############

#rule trycycler:
#	input:
#		raven = '/Volumes/archive/deardenlab/kimdainty/ASW_genome/output/raven_assembly/assembly.fasta'
#		redbean = '/Volumes/archive/deardenlab/kimdainty/ASW_genome/output/wtdg2_assembly/assembly.fasta'
#		miniasm = '/Volumes/archive/deardenlab/kimdainty/ASW_genome/output/miniasm_assembly/assembly.gfa'
#		unicycler = '/Volumes/archive/deardenlab/kimdainty/ASW_genome/output/unicycler_assembly/assembly.fasta'
#		flye = '/Volumes/archive/deardenlab/kimdainty/ASW_genome/output/flye_assembly/ASW_assembly.fasta'
#	output:





###########
# masurca #
###########


rule masurca:
	input:
		'/Volumes/archive/deardenlab/kimdainty/ASW_genome/dorado_basecalled/ASW_dorado_0.5.3_duplex_basecalls.fastq'
	output:
		'/Volumes/archive/deardenlab/kimdainty/ASW_genome/output/masurca_assembly/assembly.fasta'
	threads:
		60
	log:
		'/Volumes/archive/deardenlab/kimdainty/ASW_genome/output/logs/nextpolish_assembly.log'
	shell:
		'masurca '
		'-t {threads} '
		'-r {input} '
		'2> {log}'







##############
# nextdenovo #
##############


rule nextdenovo_namechange:
	input:
		'/Volumes/archive/deardenlab/kimdainty/ASW_genome/output/nextdenovo_assembly/03.ctg_graph/nd.asm.fasta'
	output:
		'/Volumes/archive/deardenlab/kimdainty/ASW_genome/output/nextdenovo_assembly/assembly.fasta'
	shell:
		'mv {input} {output}'


rule nextdenovo:
	input:
		fofn = '/Volumes/archive/deardenlab/kimdainty/ASW_genome/input.fofn',
		cfg = '/Volumes/archive/deardenlab/kimdainty/ASW_genome/run.cfg'
	output:
		'/Volumes/archive/deardenlab/kimdainty/ASW_genome/output/nextdenovo_assembly/03.ctg_graph/nd.asm.fasta'
	log:
		'/Volumes/archive/deardenlab/kimdainty/ASW_genome/output/logs/nextdenovo_assembly.log'
	singularity:
		nextdenovo_container
	shell:
		'nextDenovo run.cfg '
		'2> {log}'






#########
# raven #
#########

rule raven:
	input:
		'/Volumes/archive/deardenlab/kimdainty/ASW_genome/dorado_basecalled/ASW_dorado_0.5.3_duplex_basecalls.fastq'
	output:
		fa = '/Volumes/archive/deardenlab/kimdainty/ASW_genome/output/raven_assembly/assembly.fasta',
		gfa = '/Volumes/archive/deardenlab/kimdainty/ASW_genome/output/raven_assembly/assembly.gfa'
	threads:
		40
	params:
		wd = '/Volumes/archive/deardenlab/kimdainty/ASW_genome/output/raven_assembly/'
	log:
		'/Volumes/archive/deardenlab/kimdainty/ASW_genome/output/logs/raven_assembly.log'
	singularity:
		raven_container
	shell:
		'cd {params.wd} || exit 1 ; '
		'raven '
		'{input} '
		'-t {threads} '
		'-p 2 '
		'--resume '
		'--graphical-fragment-assembly {output.gfa} '
		'> {output.fa} '
		'2> {log}'
		# Can print this in gfa format with 





###################
# wtdbg2 'Redbean #
###################

# remane file for busco purposes
rule redbean_rename:
	input:
		'/Volumes/archive/deardenlab/kimdainty/ASW_genome/output/wtdg2_assembly/assembly.ctg.fa'
	output:
		'/Volumes/archive/deardenlab/kimdainty/ASW_genome/output/wtdg2_assembly/assembly.fasta'
	shell:
		'mv {input} {output}'



# then make consensus
rule redbean_consensus:
	input:
		'/Volumes/archive/deardenlab/kimdainty/ASW_genome/output/wtdg2_assembly/assembly.ctg.lay.gz'
	output:
		'/Volumes/archive/deardenlab/kimdainty/ASW_genome/output/wtdg2_assembly/assembly.ctg.fa'
	threads:
		40
	log:
		'/Volumes/archive/deardenlab/kimdainty/ASW_genome/output/logs/wtdbg2_consensus.log'
	singularity:
		wtdbg2_container
	shell:
		'wtpoa-cns '
		'-i {input} '
		'-o {output} '
		'-t {threads} '
		'2> {log}'



# assemble contigs first
rule redbean_assembly:
	input:
		'/Volumes/archive/deardenlab/kimdainty/ASW_genome/dorado_basecalled/ASW_dorado_0.5.3_duplex_basecalls.fastq'
	output:
		'/Volumes/archive/deardenlab/kimdainty/ASW_genome/output/wtdg2_assembly/assembly.ctg.lay.gz'
	threads:
		40
	log:
		'/Volumes/archive/deardenlab/kimdainty/ASW_genome/output/logs/wtdbg2_assembly.log'
	singularity:
		wtdbg2_container
	shell:
		'wtdbg2 '
		'-x ont '
		'-i {input} '
		'-fo /Volumes/archive/deardenlab/kimdainty/ASW_genome/output/wtdg2_assembly/assembly '
		'-g 220m '
		'-t {threads} '
		'2> {log}'



###########
# miniasm #
###########

# Generate fasta from gfa
rule gfa_to_fasta:
	input:
		'/Volumes/archive/deardenlab/kimdainty/ASW_genome/output/miniasm_assembly/assembly.gfa'
	output:
		'/Volumes/archive/deardenlab/kimdainty/ASW_genome/output/miniasm_assembly/assembly.fasta'
	shell:
		"awk '/^S/{{print \">\"$2\"\\n\"$3}}' {input} > {output}"




# Polish assembly with minipolish
rule minipolish:
	input:
		reads = '/Volumes/archive/deardenlab/kimdainty/ASW_genome/dorado_basecalled/ASW_dorado_0.5.3_duplex_basecalls.fastq',
		gfa = '/Volumes/archive/deardenlab/kimdainty/ASW_genome/output/miniasm_assembly/unpolished_assembly.gfa'
	output:
		'/Volumes/archive/deardenlab/kimdainty/ASW_genome/output/miniasm_assembly/assembly.gfa'
	threads:
		40
	log:
		'/Volumes/archive/deardenlab/kimdainty/ASW_genome/output/logs/minimap2.log'
	singularity:
		minipolish_container
	shell:
		'minipolish '
		'--threads {threads} '
		'2> {log} '
		'{input.reads} {input.gfa} > {output}'


# Run miniasm to make unpolished assembly
rule miniasm_assembly:
	input:
		reads = '/Volumes/archive/deardenlab/kimdainty/ASW_genome/dorado_basecalled/ASW_dorado_0.5.3_duplex_basecalls.fastq',
		paf = '/Volumes/archive/deardenlab/kimdainty/ASW_genome/output/miniasm_assembly/read_overlaps.paf'
	output:
		'/Volumes/archive/deardenlab/kimdainty/ASW_genome/output/miniasm_assembly/unpolished_assembly.gfa'
	threads:
		40
	log:
		'/Volumes/archive/deardenlab/kimdainty/ASW_genome/output/logs/miniasm_assembly.log'
	singularity:
		miniasm_container
	shell:
		'miniasm '
		'-f {input.reads} '
		'2> {log} '
		'{input.paf} > {output}'

# Find read overlaps
rule minimap2:
	input:
		'/Volumes/archive/deardenlab/kimdainty/ASW_genome/dorado_basecalled/ASW_dorado_0.5.3_duplex_basecalls.fastq'
	output:
		'/Volumes/archive/deardenlab/kimdainty/ASW_genome/output/miniasm_assembly/read_overlaps.paf'
	log:
		'/Volumes/archive/deardenlab/kimdainty/ASW_genome/output/logs/minimap2.log'
	singularity:
		minimap2_container
	shell:
		'minimap2 '
		'-x ava-ont '
		'{input} > {output} '
		'2> {log}'


#############
# unicycler #
#############

rule unicycler_assembly:
	input:
		'/Volumes/archive/deardenlab/kimdainty/ASW_genome/dorado_basecalled/ASW_dorado_0.5.3_duplex_basecalls.fastq'
	output:
		'/Volumes/archive/deardenlab/kimdainty/ASW_genome/output/unicycler_assembly/assembly.fasta'
	params:
		wd = '/Volumes/archive/deardenlab/kimdainty/ASW_genome/output/unicycler_assembly'
	threads:
		40
	log:
		'/Volumes/archive/deardenlab/kimdainty/ASW_genome/output/logs/unicycler_assembly.log'
	singularity:
		unicycler_container
	shell:
		'unicycler '
		'-l {input} '
		'-t {threads} '
		'&> {log} '
		'-o {params.wd}'



########
# flye #
########



rule flye_assembly:
	input:
		'/Volumes/archive/deardenlab/kimdainty/ASW_genome/dorado_basecalled/ASW_dorado_0.5.3_duplex_basecalls.fastq'
	output:
		'/Volumes/archive/deardenlab/kimdainty/ASW_genome/output/flye_assembly_new/assembly.fasta'
	log:
		'/Volumes/archive/deardenlab/kimdainty/ASW_genome/output/logs/flye_assembly.log'
	threads:
		40
	singularity:
		flye_container
	shell:
		'flye '
		'--nano-hq {input} '
		'--genome-size 1.4g '
		'-o {output} '
		'-t  {threads} '
		'2> {log}'


rule flye_meta:
	input:
		'/Volumes/archive/deardenlab/kimdainty/ASW_genome/dorado_basecalled/ASW_dorado_0.5.3_duplex_basecalls.fastq'
	output:
		'/Volumes/archive/deardenlab/kimdainty/ASW_genome/output/flye_assembly_meta/assembly.fasta'
	log:
		'/Volumes/archive/deardenlab/kimdainty/ASW_genome/output/logs/flye_meta_assembly.log'
	threads:
		40
	singularity:
		flye_container
	shell:
		'flye '
		'--nano-hq {input} '
		'--genome-size 1.4g '
		'--meta '
		'-o {output} '
		'-t  {threads} '
		'2> {log}'