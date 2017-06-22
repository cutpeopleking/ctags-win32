#!/bin/sh
#set -x

# Work directory of this repository.
if [ "$1" != "" ]; then
	workdir=$1
else
	workdir=.
fi

cd $workdir
if [ ! -f appveyor.yml ]; then
	echo "Wrong directory."
	exit 1
fi

git checkout master
git pull --no-edit

if [ ! -d ctags/src ]; then
	git submodule init
fi
git submodule update

# Get the latest ctags source code
cd ctags
ctagsoldver=$(git rev-parse HEAD)
git checkout master
git pull --no-edit
ctagsver=$(git describe --tags --always)
ctagslog_detail=$(git log --format='%H %s' $ctagsoldver..HEAD)
ctagslog=$(echo "$ctagslog_detail" | sed -e 's/^[^ ]* /* /')
cd ..

# Check if it is updated
if git diff --quiet; then
	echo "No changes found."
	exit 0
fi

# Commit the change and push it
# replace newline by \n
echo "$ctagslog_detail" | \
	sed -e 's/\([][_*^<`\\]\)/\\\1/g' | \
	sed -e 's#^\([^ ]*\) \(.*\)#* [\2](https://github.com/universal-ctags/ctags/commit/\1)#' | \
	perl -pe 's/\n/\\n/g' > gitlog.txt
git commit -a -m "ctags: Update to $ctagsver" -m "$ctagslog"
git tag $(date --rfc-3339=date).$ctagsver
git push origin master --tags