#!/bin/bash

display_help() {
    echo "Usage: $0 PROJ_NAME DOCKER_IMAGE [options...] " >&2
    echo ""
    echo "      PROJ_NAME"
    echo "          Specifies the name of the project"
    echo "          This will create a directory with the specified name in the project folder"
    echo ""
    echo "      DOCKER_IMAGE"
    echo "          Specifies the name of the docker image the project should use."
    echo ""
    echo "Options:"
    echo "          --container-name [CONTAINER NAME]"
    echo "              Specifies the name of the project's docker container."
    echo "              By default the container name will be the same as the environment name."
    echo ""
    echo "          --project-dir [PATH/TO/PROJ]"
    echo "              Specifies the directory where the projects are created."
    echo "              By default the default project folder is \$HOME\lkae_proj."
}

#required options
PROJ_NAME=$1
DOCKER_IMAGE=$2
shift 2

CONTAINER_NAME=$PROJ_NAME
PROJECT_DIR=$HOME/lkae_proj


while true; do
    if [ $# -eq 0 ];then
	echo $#
	break
    fi
    case "$1" in
        -h | --help)
            display_help
            exit 0
            ;;
        --container-name)
            CONTAINER_NAME=$2
            shift 2
            ;;
        --project-dir)
            PROJECT_DIR=$2
            shift 2
            ;;
        -*)
            echo "Error: Unknown option: $1" >&2
            exit 1
            ;;
        *)  # No more options
            break
            ;;
    esac
done


#devcontianer.json basic template
JSON="{\n
    \"name\": \"$CONTAINER_NAME\",\n
    \"image\": \"$DOCKER_IMAGE\",\n
\n
    \"settings\": {\n
        \"terminal.integrated.automationShell.linux\": \"/bin/bash\"\n
    },\n
\n
    \"extensions\":[\n
    ],\n
\n
\n  
    \"workspaceMount\": \"source=\${localWorkspaceFolder},target=/workspace,type=bind,consistency=delegated\",\n
    \"workspaceFolder\": \"/workspace\",\n
\n
    \"containerEnv\": {\n
        \"WORKSPACE\": \"/workspace\"\n
    },\n
\n
    \"runArgs\": [\"--privileged\", \"--device=/dev/kvm:/dev/kvm\"]\n
}"


#create the directory structure
mkdir -p $PROJECT_DIR/$PROJ_NAME/.devcontainer

#populate the container config
echo -e $JSON > $PROJECT_DIR/$PROJ_NAME/.devcontainer/devcontainer.json

#launch VS Code
cd $PROJECT_DIR/$PROJ_NAME && code .
