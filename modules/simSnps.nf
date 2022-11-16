#!/usr/bin/env nextflow

process simSnps {
   tag { "${chrm}_sim" }
   label "oneCpu"
   conda "$baseDir/conda/pysam.yaml"
    

   input:        
        tuple val(chrm), path(vcfFiles)

   output:        
        path("Sim_*")

   script:     
       def (vcfFile, vcfIndex) = vcfFiles
       def distance = params.distance
       def numSim = params.numSim
       def initRow = params.initRow

   """

    python $baseDir/bin/simSnps.py ${vcfFile} ${distance} ${numSim} ${initRow}

   """
}


process vcfIndex {
   tag { "${nSim}_vcfIndex" }
   label "oneCpu"
   conda "$baseDir/conda/bcftools.yaml"
    

   input:        
        path(vcfFile)

   output:        
        tuple val(nSim), path("NSim_*.vcf.gz"), path("NSim_*.csi")

   script:     
 	    def samBaseName              = vcfFile.baseName
        nSim                         = samBaseName.split("\\.")[0].split("_")[0]+"_"+samBaseName.split("\\.")[0].split("_")[1]
        def newSuffix = "NSim"

   """
 
    cp $vcfFile ${newSuffix}_${vcfFile}

    bcftools index ${newSuffix}_${vcfFile}


   """
}

process mergeVcf{

   tag { "${nSim}_mergeVcf" }
   publishDir(params.outSimVcfDir, pattern:"Merged_Sorted*.vcf.{gz,gz.csi}", mode:"copy")
   label "oneCpu"
   conda "$baseDir/conda/bcftools.yaml"
    

   input:        
        tuple val(nSim), path(vcfFiles), path(vcfIdxFiles)

   output:        
        tuple val(nSim), path("Merged_Sorted*.vcf.gz"), path("Merged_Sorted*.csi")

   script:     

   """
 
    bcftools concat -O b -o Merged_${nSim}.bcf ${vcfFiles}

    bcftools sort -O z -o Merged_Sorted_${nSim}.vcf.gz Merged_${nSim}.bcf

    bcftools index Merged_Sorted_${nSim}.vcf.gz


   """

}

workflow SIMSNPS {
    take:
        filteredVcfs
    main:
        simVcfTup = simSnps(filteredVcfs)
        simVcfTup
            .collect()
            .flatten()
            .set{simVcf}
       combinedVcfBySim = vcfIndex(simVcf).groupTuple()
       mergeVcfOut = mergeVcf(combinedVcfBySim)
   emit:
      mergeVcfOut = mergeVcfOut
}
