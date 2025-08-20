
IMAGE_VERSION=latest

USER_DATA_DIR="$(pwd)/user_data"
LOCAL_CACHE_DIR="$(pwd)/vep_cache"

docker pull acanalungo/wgs-inspector:$IMAGE_VERSION

docker run -it \
	-v $USER_DATA_DIR:/opt/wgs-inspector/user_data \
	-v $LOCAL_CACHE_DIR:/opt/vep_cache \
	acanalungo/wgs-inspector:$IMAGE_VERSION \
	/bin/bash
