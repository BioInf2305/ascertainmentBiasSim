#!/usr/bin/env nextflow

process runStack {
   tag { "${nSim}_stack" }
   publishDir(params.outStacksDir, pattern:"*.{tsv,treemixIn.gz}", mode:"copy")
   label "oneCpu"
   conda "$baseDir/conda/stack.yaml"
    

   input:        
        tuple val(nSim), path(vcfFile), path(vcfIdxFile)

   output:        
        tuple val(nSim), path("*treemixIn.gz"), path("*.tsv")

   script:     
        def popMap = params.popMap
    
   """
    populations -V ${vcfFile} -M ${popMap} -O ./ --treemix
    
    awk 'NR>1{print}' *.treemix|pigz -c > ${nSim}.treemixIn.gz

   """
}


process runTreemix {
   tag { "${nSim}_treemix" }
   publishDir(params.outStacksDir, pattern:"*.{cov.gz,modelcov.gz,covse.gz,edges.gz,vertices.gz,llik, treeout.gz}", mode:"copy")
   label "oneCpu"
   conda "$baseDir/conda/treemix.yaml"
    

   input:        
        tuple val(nSim), path(treemixIn), path(tsv)

   output:        
        tuple val(nSim), path("*.{cov.gz,modelcov.gz,covse.gz,edges.gz,vertices.gz,llik, treeout.gz}")

   script:     
        def popMap = params.popMap
        def block = params.block
        def migEdge = params.migEdge
    
   """
    
    treemix -i ${treemixIn} -k ${block} -root Outgroup -o ${nSim}_m0_treemix_out

    treemix -i ${treemixIn} -k ${block} -root Outgroup -m ${migEdge} -o ${nSim}_m${migEdge}treemix_out

   """
}

process runDsuite {
   tag { "${nSim}_Dsuite" }
   publishDir(params.outStacksDir, pattern:"*.txt", mode:"copy")
   label "oneCpu"
   conda "$baseDir/conda/treemix.yaml"
    

   input:        
        tuple val(nSim), path(vcfFile), path(vcfIdx)

   output:        
        tuple val(nSim), path("*.txt")

   script:     
        def jkNum = params.jkNum
        def popMap = params.popMap
    
   """
    $baseDir/bin/Dsuite Dtrios ${vcfFile} ${popMap} -o ${nSim}

   """
}

workflow RUNPOPGEN {
    take:
       simMergedVcf
    main:
        treemixIn = runStack(simMergedVcf)
        runTreemix(treemixIn)
        runDsuite(simMergedVcf)
}
