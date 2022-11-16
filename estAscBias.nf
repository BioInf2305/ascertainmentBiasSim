#!/usr/bin/env nextflow

nextflow.enable.dsl=2







channel 
    .fromFilePairs( params.vcfFilesPath )
    //.map { vcfFileKeys,files -> tuple(vcfFileKeys.replaceAll(/.filt.step3/,''),files)}
    .set { vcfFiles }

include { SIMSNPS } from "${baseDir}/modules/simSnps" addParams(
        distance : params.distance,
        numSim : params.numSim,
        initRow : params.initRow
        )

include { RUNPOPGEN } from "${baseDir}/modules/popGen" addParams(
        popMap : params.popMap
        )

workflow {

     mergedSimVcf = SIMSNPS(vcfFiles)
     RUNPOPGEN(mergedSimVcf)
    
}
