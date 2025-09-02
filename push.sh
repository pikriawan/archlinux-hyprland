#!/bin/bash
push_message="$@"

if [ -z "$push_message" ]; then
    push_message="update"
fi

rm -f .config.tar.xz
rm -f .local.tar.xz
tar -cf .config.tar.xz .config/
tar -cf .local.tar.xz .local/
git add .
git commit -m "$push_message"
git push
echo "Push successful"
