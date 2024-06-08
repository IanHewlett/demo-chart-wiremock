#!/usr/bin/env just --justfile
repo := "ghcr.io/ianhewlett"
chart := "wiremock"
release := "wiremock"

_default:
  @just --list

scan tag:
  just _scan {{chart}} {{release}}

package tag:
  just _package {{chart}}

login:
  just _login {{repo}}

push tag:
  just _push {{chart}} {{tag}}

sign tag:
  just _sign {{repo}} {{chart}} {{tag}}

ci-on-git-push tag: (scan tag)

ci-on-git-tag tag: (scan tag) (package tag) login (push tag) (sign tag)

_template chart release:
  helm template --dependency-update --no-hooks {{release}} ./charts/{{chart}} \
    --values ./charts/{{chart}}/values.yaml

_scan chart release allow_scan_fail="true":
  just _template {{chart}} {{release}} > tmp-manifest.yaml
  snyk iac test tmp-manifest.yaml || {{allow_scan_fail}}
  rm -rf tmp-manifest.yaml

_package chart:
  helm package ./charts/{{chart}} --dependency-update --destination ./packages

_login repo:
  docker login -u username -p "$GITHUB_TOKEN" {{repo}}

_push chart tag:
  helm push ./packages/{{chart}}-{{tag}}.tgz oci://{{repo}}/charts

_sign repo chart tag:
  VAULT_NAMESPACE=admin \
    cosign sign --key hashivault://image_signing_key {{repo}}/charts/{{chart}}:{{tag}}
