
IMAGE_VERSION=0.0.2

docker build \
    -f Dockerfile \
    -t wgs-inspector:$IMAGE_VERSION \
    --progress plain \
    .

docker tag wgs-inspector:$IMAGE_VERSION \
	   acanalungo/wgs-inspector:$IMAGE_VERSION

docker tag wgs-inspector:$IMAGE_VERSION \
           acanalungo/wgs-inspector:latest

docker push acanalungo/wgs-inspector:$IMAGE_VERSION

docker push acanalungo/wgs-inspector:latest
