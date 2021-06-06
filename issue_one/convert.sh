#! /usr/bin/env bash

function to_md() {
  html=$(mktemp).html
  iconv -f UTF-8 -t UTF-8//IGNORE  -c -o ${html} ${1}
  md=$(sed "s/\.html/.md/" <<< "${1}")
  pandoc ${html} -o ${md}
  rm ${html}
  echo ${md}
}


function cleanup() {
  md=${1}
  sed -i "s/^> *//" ${md}
  sed -i "s/^+--*+//" ${md}
  sed -i "s/ *|$//" ${md}
  sed -i "s/| > *//" ${md}
  sed -i "1,4s/^\*\*\(.*\)\*\*/# \1/" ${md}
  sed -i "s/^ *\([0-9][0-9]*\) *\.*$/## \1/" ${md}
  sed -i "s/\\\\* *$//" ${md}
  t=`mktemp`
  head -n-2 ${md} > $t
  mv $t ${md}
  echo ${md}
}

for f in $*; do
  echo "[+] Processing $f..."
  md=`to_md $f`
  if ! (echo ${md} | grep -q "[A-Z0-9]\.md"); then
    echo "[+] Cleaning $md"
    cleanup ${md}
  fi
done
