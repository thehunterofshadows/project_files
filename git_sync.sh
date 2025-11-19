#!/bin/bash
if [ "$1" == "--force" ] || [ "$1" == "-f" ]; then
    git add -A && git commit -m "sync all changes" && git push --force origin main
else
    git add -A && git commit -m "sync all changes" && git push origin main
fi
