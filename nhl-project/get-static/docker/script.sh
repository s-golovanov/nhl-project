#!/bin/sh
git clone https://${GITHUB_USERNAME}:${GITHUB_TOKEN}@github.com/${GITHUB_USERNAME}/${GITHUB_REPO}.git
cp -r /app/${GITHUB_REPO}/static/. /static
rm -rf /app/${GITHUB_REPO}
