

process REGISTRATION_ANTS {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://scil.usherbrooke.ca/containers/scilus_1.6.0.sif':
        'scilus/scilus:1.6.0' }"

    input:
    tuple val(meta), path(fixedimage), path(movingimage), path(mask)

    output:
    tuple val(meta), path("*_warped.nii.gz")                                                     , emit: image
    tuple val(meta), path("*__output1Warp.nii.gz"), path ("*__output0GenericAffine.mat")         , emit: transfo_image
    tuple val(meta), path("*__revoutput0GenericAffine.mat"), path("*__output1InverseWarp.nii.gz"), emit: transfo_trk
    path "versions.yml"                                                                          , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def ants = task.ext.quick "antsRegistrationSyNQuick.sh " :  "antsRegistrationSyN.sh "
    def dimension = task.ext.dimension ? "-d " + task.ext.dimension : "-d 3"
    
    if ( task.ext.threads ) args += "-n " + task.ext.threads : ""
    if ( task.ext.initial_transform ) args += " -i " + task.ext.initial_transform : ""
    if ( task.ext.transform ) args += " -t " + task.ext.transform : ""
    if ( task.ext.histogram_bins ) args += " -r " + task.ext.histogram_bins : ""
    if ( task.ext.spline_distance ) args += " -s " + task.ext.spline_distance : ""
    if ( task.ext.gradient_step ) args += " -g " + task.ext.gradient_step : ""
    if ( task.ext.mask ) args += " -x $mask"
    if ( task.ext.type ) args += " -p " + task.ext.type : ""
    if ( task.ext.histogram_matching ) args += " -j " + task.ext.histogram_matching : ""
    if ( task.ext.repro_mode ) args += " -y " + task.ext.repro_mode : ""
    if ( task.ext.collapse_output ) args += " -z " + task.ext.collapse_output : ""
    if ( task.ext.random_seed ) args += " -e " + task.ext.random_seed : ""


    """
    export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=1
    export OMP_NUM_THREADS=1
    export OPENBLAS_NUM_THREADS=1

    $ants $dimension $fixedimage $movingimage -o output $args

    mv outputWarped.nii.gz ${prefix}__warped.nii.gz
    mv output0GenericAffine.mat ${prefix}__output0GenericAffine.mat
    mv output1InverseWarp.nii.gz ${prefix}__output1InverseWarp.nii.gz
    mv output1Warp.nii.gz ${prefix}__output1Warp.nii.gz

    antsApplyTransforms -d 3 -i $fixedimage -r $movingimage -o Linear[output.mat]\
                        -t [${prefix}__output0GenericAffine.mat,1]
    
    mv output.mat ${prefix}__revoutput0GenericAffine.mat

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ants: 2.4.3
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    
    """
    antsRegistration -help

    touch ${prefix}__t1_warped.nii.gz
    touch ${prefix}__output0GenericAffine.mat
    touch ${prefix}__revoutput0GenericAffine.mat
    touch ${prefix}__output1InverseWarp.nii.gz
    touch ${prefix}__output1Warp.nii.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ants: 2.4.3
    END_VERSIONS
    """
}
