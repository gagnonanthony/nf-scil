#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { SEGMENTATION_FSRECONALL } from '../../../../../modules/nf-scil/segmentation/fsreconall/main.nf'

// Too long, we don't test.
// To test locally, add the following lines:

workflow test_segmentation_fsreconall {


    input = [
        [ id:'test', single_end:false ], // meta map
        file(params.test_data['segmentation']['fsreconall']['anat'], checkIfExists: true),
        file(params.test_data['segmentation']['fsreconall']['license'], checkIfExists: true)
    ]

    SEGMENTATION_FSRECONALL ( input )

}
