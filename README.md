`git-resolve-conflict <strategy> <filename>`
===========================================================

> Resolve merge conflict in one file, using given strategy (--ours, --theirs, --union)
>
>     git resolve-conflict --ours package.json
>     git resolve-conflict --theirs package.json
>     git resolve-conflict --union package.json
>
>     git resolve-ours package.json
>     git resolve-theirs package.json
>     git resolve-union package.json

Why would you need it
--------------------

To be able to resolve certain well-defined types of merge conflicts, without opening mergetool.

This is particularly useful in automated merge scripts (for example, Jenkins jobs), or if you have large number of well-defined merges to resolve.

Installation
------------

  - copy `/lib/git-resolve-conflict.sh` to your `.bashrc` (this adds just `git resolve-conflict`)
  - or `npm install -g git-resolve-conflict` (this also adds 3 other helpers)

 [![Get it on npm](https://nodei.co/npm/git-resolve-conflict.png?compact=true)](https://www.npmjs.org/package/git-resolve-conflict)
 
npm installation is the recommended way, so that you can easily get updates in the future.

TL;DR
=====

It's just a tiny wrapper around [git-merge-file](https://git-scm.com/docs/git-merge-file) to simplify the API. See `./lib/git-resolve-conflict.sh`.
(I used temp files instead of process substitution to make it msys/mingw-friendly).

It's better than `git merge -Xours` because that would resolve conflicts for all files. Here we can resolve conflict for just one file.

It's better than `git checkout --ours package.json` because that would lose changes from `theirs` even if they are not conflicted.
Here we can resolve conflict using a three-way merge and keep the non-conflicted changes from both sides.

See also http://stackoverflow.com/q/39126509/245966

Description
===========

Say you have multiple git branches and you want to merge
between them, and always resolve conflicts **in a particular file** with a **fixed strategy**
(say `ours`).

For instance, you have `master` (stable) and `develop` (unstable) branches.
When code is stable you freeze the `master`, and development continues in `develop`,
which is merged to `master` every few weeks.

But then you find our bugs at regression testing stage, you fix them in `master`, and you build.
In the meantime, you also build `develop` separately. Each build bumps `version` field in `package.json`.

Sice those branches can be built separately, a file like `package.json`
will be modified in both branches, and there'll be a merge conflict due to `version` field
being changed in both branches.

How to easily **resolve the merge conflict** in an **automated manner** (script) in such a situation?


The usual suspects
==================

- `git merge -Xours`: this will resolve ALL conflicts in ALL files using the same strategy. This might be too much.
(For instance, I might want to have an automatic merging script, which can do a successful conflict resolution
only if `foobar.json` is *the only file that was modified*; on any other files modified, the merge should fail)

- `git checkout --ours filename.txt`: this will **discard** ALL the changes from `theirs` version, which is brutal.
There might be some valid, non-conflicting changes that will be discarded this way.

- What we need is something like `git-resolve-conflict --ours filename.txt`

**Check `./lib/git-resolve-conflict.sh` in this repo!**


Initial situation
=================

    $ git log --oneline base
    be4abab add git-resolve-conflict script
    ...

    $ git log --oneline master
    0ea4d05 1.0.2
    d94a1dc change in master: add dependencies
    386ae99 1.0.1
    6160dea change in master
    be4abab add git-resolve-conflict script
    ...

    $ git log --oneline develop
    f2fefc6 2.0.1
    b8c66c9 change in develop
    263aa5f 2.0.0
    be4abab add git-resolve-conflict script
    ...

Goal
=================

We want to merge `develop` into `master` and auto-resolve conflicts in `package.json` using strategy `--ours`

    $ git log --oneline merge_master_to_develop
    7cde612 Merge branch 'master' into merge_master_to_develop
    0ea4d05 1.0.2
    d94a1dc change in master: add dependencies
    f2fefc6 2.0.1
    b8c66c9 change in develop
    263aa5f 2.0.0
    386ae99 1.0.1
    6160dea change in master
    be4abab add git-resolve-conflict script
    ...


We need to be cautious
======================

We have changes in `master` that would be lost on merge if we did a brutal `git checkout --ours package.json`

    $ git show master^
    commit d94a1dc5ff0aba1c0d9c2a3dd8f9bec3147578d2
    Author: jakub-g <jakub.g.opensource@gmail.com>
    Date:   Wed Aug 24 14:13:16 2016 +0200

        change in master: add dependencies

    diff --git a/package.json b/package.json
    index f709434..a609d8c 100644
    --- a/package.json
    +++ b/package.json
    @@ -6,6 +6,10 @@
       "scripts": {
         "test": "echo \"Error: no test specified\" && exit 1"
       },
    +  "dependencies": {
    +    "foobar": "1.0.0",
    +    "quux": "2.0.0"
    +  },
       "author": "",
       "license": "ISC"
     }


Let's merge
===========

    $ git checkout develop
    Switched to branch 'develop'

    $ git checkout -b merge_master_to_develop
    Switched to a new branch 'merge_master_to_develop'

    $ git merge master
    Auto-merging package.json
    CONFLICT (content): Merge conflict in package.json
    Automatic merge failed; fix conflicts and then commit the result.

    me@mymachine /d/git/merge-file-ours-poc (merge_master_to_develop *+|MERGING)
    $ git diff
    diff --cc package.json
    index 75c469b,f709434..0000000
    --- a/package.json
    +++ b/package.json
    @@@ -1,6 -1,6 +1,12 @@@
      {
        "name": "merge-file-ours-poc",
    ++<<<<<<< HEAD
     +  "version": "2.0.1",
    ++||||||| merged common ancestors
    ++  "version": "1.0.0",
    ++=======
    +   "version": "1.0.2",
    ++>>>>>>> master
        "description": "merge-file-ours proof of concept\r ================================",
        "main": "index.js",
        "scripts": {

    me@mymachine /d/git/merge-file-ours-poc (merge_master_to_develop *+|MERGING)
    $ cat package.json
    {
      "name": "merge-file-ours-poc",
    <<<<<<< HEAD
      "version": "2.0.1",
    ||||||| merged common ancestors
      "version": "1.0.0",
    =======
      "version": "1.0.2",
    >>>>>>> master
      "description": "merge-file-ours proof of concept\r ================================",
      "main": "index.js",
      "scripts": {
        "test": "echo \"Error: no test specified\" && exit 1"
      },
      "dependencies": {
        "foobar": "1.0.0",
        "quux": "2.0.0"
      },
      "author": "",
      "license": "ISC"
    }

`git-resolve-conflict` to the rescue
====================================

    ######################################################################################
    ##          doing `git checkout --ours package.json` at this point is WRONG!        ##
    ##                it would lose the changes in `master^` commit                     ##
    ##                            we need something better                              ##
    ######################################################################################


    me@mymachine /d/gh/merge-file-ours-poc (merge_master_to_develop *+|MERGING)
    $ source ./git-resolve-conflict.sh

    $ git-resolve-conflict
    Usage:   git-resolve-conflict <strategy> <file>

    Example: git-resolve-conflict --ours package.json
    Example: git-resolve-conflict --union package.json
    Example: git-resolve-conflict --theirs package.json

    $ git-resolve-conflict --ours package.json

    $ git diff

    $ git diff --cached
    diff --git a/added-in-master.txt b/added-in-master.txt
    new file mode 100644
    index 0000000..9cef8af
    --- /dev/null
    +++ b/added-in-master.txt
    @@ -0,0 +1 @@
    +added in master
    diff --git a/package.json b/package.json
    index 75c469b..03f513b 100644
    --- a/package.json
    +++ b/package.json
    @@ -6,6 +6,10 @@
       "scripts": {
         "test": "echo \"Error: no test specified\" && exit 1"
       },
    +  "dependencies": {
    +    "foobar": "1.0.0",
    +    "quux": "2.0.0"
    +  },
       "author": "",
       "license": "ISC"
     }

    $ git status
    On branch merge_master_to_develop
    All conflicts fixed but you are still merging.
      (use "git commit" to conclude merge)

    Changes to be committed:

            new file:   added-in-master.txt
            modified:   package.json

    $ git commit
    [merge_master_to_develop aed5278] Merge branch 'master' into merge_master_to_develop

Final situation
============================================

    me@mymachine /d/gh/merge-file-ours-poc (merge_master_to_develop)
    $ cat package.json
    {
      "name": "merge-file-ours-poc",
      "version": "2.0.1",
      "description": "merge-file-ours proof of concept\r ================================",
      "main": "index.js",
      "scripts": {
        "test": "echo \"Error: no test specified\" && exit 1"
      },
      "dependencies": {
        "foobar": "1.0.0",
        "quux": "2.0.0"
      },
      "author": "",
      "license": "ISC"
    }

Everything is fine, merge resolved correctly!

- version is 2.0.1 (taken from `develop`)
- dependencies are not lost (taken from `master`)
