#!/bin/sh

main() {
  case ${1} in
    create)
      create_user "${2}"
      ;;
    delete)
      delete_user "${2}"
      ;;
    *)
      echo "Usage: ${0} {create|delete} <username>"
      exit 1
      ;;
  esac
}

create_user(){
  USERNAME="${1:-}"
  PASSWORD="$(date +%s | sha256sum | base64 | head -c 32)"

  if [ -z "${AWS_ACCESS_KEY_ID}" ] || [ -z "${AWS_SECRET_ACCESS_KEY}" ]
  then
    echo "Missing AWS_ACCESS_KEY_ID or AWS_SECRET_ACCESS_KEY"
    exit 1
  fi

  if [ -z "${USERNAME}" ]
  then
    echo "Missing USERNAME"
    exit 1
  fi

  # create new user
  aws iam create-user --user-name "${USERNAME}"

  # set the default password
  aws iam create-login-profile --user-name "${USERNAME}" --password "${PASSWORD}" --password-reset-required

  # add user to default groups
  for GROUP in presales everyone efs manage_certs
  do
    aws iam add-user-to-group --user-name "${USERNAME}" --group-name "${GROUP}"
  done

  # create access key
  ACCESS_KEY="$(aws iam create-access-key --user-name "${USERNAME}")"

  echo;echo "User account creation complete!"
  echo "Account URL: https://$(aws iam list-account-aliases | jq -r '.AccountAliases|.[]').signin.aws.amazon.com/console"
  echo "Username: ${USERNAME}"
  echo "Password: ${PASSWORD}"
  echo "Access Key ID: $(echo "${ACCESS_KEY}" | jq -r .AccessKey.AccessKeyId)"
  echo "Secret Access Key: $(echo "${ACCESS_KEY}" | jq -r .AccessKey.SecretAccessKey)"
}

delete_user() {
  USERNAME="${1:-}"

  if [ -z "${AWS_ACCESS_KEY_ID}" ] || [ -z "${AWS_SECRET_ACCESS_KEY}" ]
  then
    echo "Missing AWS_ACCESS_KEY_ID or AWS_SECRET_ACCESS_KEY"
    exit 1
  fi

  if [ -z "${USERNAME}" ]
  then
    echo "Missing USERNAME"
    exit 1
  fi

  # remove user login profile
  aws iam delete-login-profile --user-name "${USERNAME}"

  # remove user from all groups
  for GROUP in $(aws iam list-groups-for-user --user-name "${USERNAME}" | jq -r '.Groups|.[].GroupName')
  do
    aws iam remove-user-from-group --user-name "${USERNAME}" --group-name "${GROUP}"
  done

  # remove user's access keys
  for KEY in $(aws iam list-access-keys --user-name "${USERNAME}" | jq -r '.AccessKeyMetadata|.[].AccessKeyId')
  do
    aws iam delete-access-key --user-name "${USERNAME}" --access-key-id "${KEY}"
  done

  # remove user
  aws iam delete-user --user-name "${USERNAME}"

  echo;echo "User account removal complete!"
  echo "Username: ${USERNAME}"
}

main "${@}"
