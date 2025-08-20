
IMAGE_VERSION=0.0.10

docker build \
    -f Dockerfile \
    -t wgs-inspector-dev:$IMAGE_VERSION \
    --progress plain \
    .

docker tag wgs-inspector-dev:$IMAGE_VERSION \
	   acanalungo/wgs-inspector-dev:$IMAGE_VERSION

docker tag wgs-inspector-dev:$IMAGE_VERSION \
           acanalungo/wgs-inspector-dev:latest

docker push acanalungo/wgs-inspector-dev:$IMAGE_VERSION

docker push acanalungo/wgs-inspector-dev:latest
