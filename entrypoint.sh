#!/bin/sh

main() {
  case ${1} in
    create)
      create_user "${2}" "${3}"
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
  USER_TYPE="${2:-user}"
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

  if [ "${USER_TYPE}" != "user" ] && [ "${USER_TYPE}" != "admin" ]
  then
    echo "Invalid user type (${USER_TYPE})"
    echo "Valid types: {user|admin}"
    exit 1
  fi

  # create new user
  echo "Creating user ${USERNAME}..."
  aws iam create-user --user-name "${USERNAME}"
  echo "done";echo

  # set the default password
  echo "Setting the default password for ${USERNAME}..."
  aws iam create-login-profile --user-name "${USERNAME}" --password "${PASSWORD}" --password-reset-required
  echo "done";echo

  # add user to default groups
  echo "Adding default groups for ${USERNAME}..."
  for GROUP in presales everyone efs manage_certs
  do
    aws iam add-user-to-group --user-name "${USERNAME}" --group-name "${GROUP}"
    echo "  Added ${USERNAME} to ${GROUP}"
  done
  echo "done";echo

  # add user to admin groups
  if [ "${USER_TYPE}" = "admin" ]
  then
    echo "Adding admin groups for ${USERNAME}..."
    for GROUP in ad_admin admin
    do
      aws iam add-user-to-group --user-name "${USERNAME}" --group-name "${GROUP}"
      echo "  Added ${USERNAME} to ${GROUP}"
    done
    echo "done";echo
  fi

  # create access key
  echo "Creating access key for ${USERNAME}..."
  ACCESS_KEY="$(aws iam create-access-key --user-name "${USERNAME}")"
  echo "done";echo

  echo "User account creation complete!"
  echo "Account URL: https://$(aws iam list-account-aliases | jq -r '.AccountAliases|.[]').signin.aws.amazon.com/console"
  echo "Account type: ${USER_TYPE}"
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
  echo "Removing login profile for ${USERNAME}..."
  aws iam delete-login-profile --user-name "${USERNAME}"
  echo "done";echo

  # remove user from all groups
  echo "Removing all groups for ${USERNAME}..."
  for GROUP in $(aws iam list-groups-for-user --user-name "${USERNAME}" | jq -r '.Groups|.[].GroupName')
  do
    aws iam remove-user-from-group --user-name "${USERNAME}" --group-name "${GROUP}"
    echo "  Removed ${USERNAME} from ${GROUP}"
  done
  echo "done";echo

  # remove user's access keys
  echo "Removing all access keys for ${USERNAME}..."
  for KEY in $(aws iam list-access-keys --user-name "${USERNAME}" | jq -r '.AccessKeyMetadata|.[].AccessKeyId')
  do
    aws iam delete-access-key --user-name "${USERNAME}" --access-key-id "${KEY}"
  done
  echo "done";echo

  # deactivate and remove all MFA devices
  echo "Removing all MFA devices for ${USERNAME}..."
  for MFA in $(aws iam list-mfa-devices --user-name "${USERNAME}" | jq -r '.MFADevices|.[].SerialNumber')
  do
    aws iam deactivate-mfa-device --user-name "${USERNAME}" --serial-number "${MFA}"
    echo "  Deactivated ${MFA} from ${USERNAME}"
    aws iam delete-virtual-mfa-device --serial-number "${MFA}"
    echo "  Deleted ${MFA}"
  done
  echo "done";echo

  # remove user
  echo "Removing user ${USERNAME}..."
  aws iam delete-user --user-name "${USERNAME}"
  echo "done";echo

  echo "User account removal complete!"
  echo "Username: ${USERNAME}"
}

main "${@}"
