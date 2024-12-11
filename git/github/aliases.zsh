alias sbt='services_by_team'

fsbt() {
  services_by_team | jq '[.finance[] | select(. != "argo-ops" and . != "backend-coding-guidelines")]'
}

g2fs() {
  go_to_finance_services
}