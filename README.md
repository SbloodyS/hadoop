Apache Hadoop image

This is the definition of the Apache Hadoop image. This contains amd64 and arm64 image.

## Build
To create a local version of this image use the following command:
```bash
# AMD64
docker build --build-arg TINI_PLATFORM="amd64" -t sbloodys/hadoop:3.3.6 .

# ARM64
docker build --build-arg TINI_PLATFORM="arm64" -t sbloodys/hadoop:3.3.6 .
```

Start a hadoop cluster container with the following command:
```bash
docker-compose -f docker-compose-hadoop.yaml up -d
```

## License

Licensed under the [Apache License, Version 2.0](LICENSE)
