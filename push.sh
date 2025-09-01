#!/bin/bash
if [ -z "$@" ]; then
    echo "No commit message. Push aborted"
    exit 1
fi

rm .config.tar.xz
rm bin.tar.xz
tar -cf .config.tar.xz .config/
tar -cf bin.tar.xz bin/
git add .
git commit -m "$@"
git push
echo "Push successfull"
