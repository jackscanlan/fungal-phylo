process CHANNEL_TO_FILE {
    def module_name = "channel_to_file"
    // tag "$sample"
    label "small"

    input:
    /// NOTE: This process requires channel_data to be the flattened but still nested data of a channel, ie. via '.collect ( flat: false )'
    val(channel_data)
    val(file_type)
    val(header)

    output:
    path("out.*")
    

    publishDir "${projectDir}/output/modules/${module_name}", mode: 'copy'

    // when: 

    script:
    def module_script = "${module_name}.sh"
    """
    #!/usr/bin/bash

    ### run module code
    bash ${module_name}.sh \
        ${projectDir} \
        "${channel_data}" \
        ${file_type} \
        ${header}
    
    """

}