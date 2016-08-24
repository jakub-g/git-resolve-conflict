`git-resolve-conflict <strategy> <filename>`
===========================================================

> Resolve merge conflict in one file, using given strategy (--ours, --theirs, --union)

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

**TL;DR** we need to use [git-merge-file](https://git-scm.com/docs/git-merge-file) but its API is not easy. Hence I wrote a wrapper `./git-resolve-conflict.sh` around it (I used temp files instead of process substitution to make it msys/mingw-friendly).

The usual suspects
==================

- `git merge -Xours`: this will resolve ALL conflicts in ALL files using the same strategy. This might be too much.
(For instance, I might want to have an automatic merging script, which can do a successful conflict resolution
only if `foobar.json` is *the only file that was modified*; on any other files modified, the merge should fail)

- `git checkout --ours filename.txt`: this will **discard** ALL the changes from `theirs` version, which is brutal.
There might be some valid, non-conflicting changes that will be discarded this way.

- What we need is something like `git-resolve-conflict --ours filename.txt`

**Check `./git-resolve-conflict.sh` in this repo!**


Initial situation
=================

    me@mymachine /d/gh/merge-file-ours-poc (base)
    $ git log --oneline base
    be4abab add git-resolve-conflict script
    0bb70f5 npm init
    41c7b17 init

    me@mymachine /d/gh/merge-file-ours-poc (base)
    $ git log --oneline master
    0ea4d05 1.0.2
    d94a1dc change in master: add dependencies
    386ae99 1.0.1
    6160dea change in master
    be4abab add git-resolve-conflict script
    0bb70f5 npm init
    41c7b17 init

    me@mymachine /d/gh/merge-file-ours-poc (base)
    $ git log --oneline develop
    f2fefc6 2.0.1
    b8c66c9 change in develop
    263aa5f 2.0.0
    be4abab add git-resolve-conflict script
    0bb70f5 npm init
    41c7b17 init

Goal
=================

We want to merge `develop` into `master` and auto-resolve conflicts in `package.json` using strategy `--ours`

    me@mymachine /d/gh/merge-file-ours-poc (base)
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
    0bb70f5 npm init
    41c7b17 init


Beware
======

We have changes in `master` that would be lost on merge if we did a brutal `git checkout --ours package.json`

    me@mymachine /d/gh/merge-file-ours-poc (develop)

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
==============

    me@mymachine /d/gh/merge-file-ours-poc (develop)
    $ git checkout develop
    Switched to branch 'develop'


    me@mymachine /d/gh/merge-file-ours-poc (develop)
    $ git checkout -b merge_master_to_develop
    Switched to a new branch 'merge_master_to_develop'


    me@mymachine /d/gh/merge-file-ours-poc (merge_master_to_develop)
    $ git merge master
    Auto-merging package.json
    CONFLICT (content): Merge conflict in package.json
    Automatic merge failed; fix conflicts and then commit the result.


    me@mymachine /d/gh/merge-file-ours-poc (merge_master_to_develop *+|MERGING)
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


    me@mymachine /d/gh/merge-file-ours-poc (merge_master_to_develop *+|MERGING)
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


    me@mymachine /d/gh/merge-file-ours-poc (merge_master_to_develop *+|MERGING)
    $ git-resolve-conflict
    Usage:   git-resolve-conflict <strategy> <file>

    Example: git-resolve-conflict --ours package.json
    Example: git-resolve-conflict --union package.json
    Example: git-resolve-conflict --theirs package.json


    me@mymachine /d/gh/merge-file-ours-poc (merge_master_to_develop *+|MERGING)
    $ git-resolve-conflict --ours package.json


    me@mymachine /d/gh/merge-file-ours-poc (merge_master_to_develop +|MERGING)
    $ git diff


    me@mymachine /d/gh/merge-file-ours-poc (merge_master_to_develop +|MERGING)
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

    me@mymachine /d/gh/merge-file-ours-poc (merge_master_to_develop +|MERGING)
    $ git status
    On branch merge_master_to_develop
    All conflicts fixed but you are still merging.
      (use "git commit" to conclude merge)

    Changes to be committed:

            new file:   added-in-master.txt
            modified:   package.json


    me@mymachine /d/gh/merge-file-ours-poc (merge_master_to_develop +|MERGING)
    $ git commit
    [merge_master_to_develop aed5278] Merge branch 'master' into merge_master_to_develop

Everything is fine, merge resolved correctly
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
