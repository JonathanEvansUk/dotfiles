
# Method to perform aws sso login
asl () {
  aws sso login --sso-session=paytrix;
  token;
}


token () {
  token=$(aws codeartifact get-authorization-token --profile paytrix-eks-deployment --domain paytrix --domain-owner 296700980044 --region eu-west-2 --query authorizationToken --output text)

  # backup settings.xml file
  cp ~/.m2/settings.xml ~/.m2/settings.xml.bak

  if [ $? -eq 0 ]; then
    echo "Token fetched successfully:"
    echo "${token}"
    export CODEARTIFACT_AUTH_TOKEN="${token}"
    xmlstarlet ed -N s="http://maven.apache.org/SETTINGS/1.2.0" \
      -u "//s:server/s:id[text()='paytrix-development-paytrix-repository']/../s:password" \
      -v $token ~/.m2/settings.xml.bak \
      >~/.m2/settings.xml
  else
    echo "Failed to fetch token"
  fi
}