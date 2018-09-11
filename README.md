mbentley/aws-manage-user
========================

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
  mbentley/aws-manage-user \
  create foo user
```

For `create`, the script takes two arguments: `username` and `user_type` where `user_type` is either `user` or `admin`.


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
  mbentley/aws-manage-user \
  delete foo
```

For `delete`, the script takes one argument: `username`.

## List Users
```
docker run --rm \
  -u "$(id -u)" \
  -w /data \
  -e AWS_ACCESS_KEY_ID \
  -e AWS_SECRET_ACCESS_KEY \
  -e AWS_DEFAULT_REGION \
  --tmpfs /tmp \
  -v "${PWD}":/data \
  mbentley/aws-manage-user \
  list
```

## MFA Check Users
```
docker run --rm \
  -u "$(id -u)" \
  -w /data \
  -e AWS_ACCESS_KEY_ID \
  -e AWS_SECRET_ACCESS_KEY \
  -e AWS_DEFAULT_REGION \
  --tmpfs /tmp \
  -v "${PWD}":/data \
  mbentley/aws-manage-user \
  mfacheck
```
