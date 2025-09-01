#!/bin/bash
push_message="$@"

if [ -z "$push_message" ]; then
    push_message="update"
fi

rm .config.tar.xz
rm bin.tar.xz
tar -cf .config.tar.xz .config/
tar -cf bin.tar.xz bin/
git add .
git commit -m "$push_message"
git push
echo "Push successful"
