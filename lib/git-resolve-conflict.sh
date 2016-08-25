#!/bin/bash

git-resolve-conflict() {
  STRATEGY="$1"
  FILE_PATH="$2"

  if [ "$1" == "--version" ]; then
    DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    cat $DIR/../package.json | grep version | sed 's/,//'
    return
  fi

  if [ -z "$FILE_PATH" ] || [ -z "$STRATEGY" ]; then
    echo "Usage:   git-resolve-conflict <strategy> <file>"
    echo ""
    echo "Example: git-resolve-conflict --ours package.json"
    echo "Example: git-resolve-conflict --union package.json"
    echo "Example: git-resolve-conflict --theirs package.json"
    return
  fi

  git show :1:"$FILE_PATH" > ./tmp.common
  git show :2:"$FILE_PATH" > ./tmp.ours
  git show :3:"$FILE_PATH" > ./tmp.theirs

  git merge-file "$STRATEGY" -p ./tmp.ours ./tmp.common ./tmp.theirs > "$FILE_PATH"
  git add "$FILE_PATH"

  rm ./tmp.common
  rm ./tmp.ours
  rm ./tmp.theirs
}
