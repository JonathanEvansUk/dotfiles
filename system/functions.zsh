function open_urls {
  echo "calling openUrls"
  set -x
  openUrls "$@"
  set +x
}