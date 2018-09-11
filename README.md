mbentley/awscli
===============

docker image for creating and deleting users
based off of mbentley/awscli

## Create User `foo`
```
docker run --rm \
  -u "$(id -u)" \
  -w /data \
  -e AWS_ACCESS_KEY_ID \
  -e AWS_SECRET_ACCESS_KEY \
  -e AWS_DEFAULT_REGION \
  --tmpfs /tmp \
  -v "${PWD}":/data \
  mbentley/aws-manage-user create foo
```

## Delete User `foo`
```
docker run --rm \
  -u "$(id -u)" \
  -w /data \
  -e AWS_ACCESS_KEY_ID \
  -e AWS_SECRET_ACCESS_KEY \
  -e AWS_DEFAULT_REGION \
  --tmpfs /tmp \
  -v "${PWD}":/data \
  mbentley/aws-manage-user delete foo
```
