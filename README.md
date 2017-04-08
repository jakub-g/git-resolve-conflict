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

  - copy [`/lib/git-resolve-conflict.sh`](https://github.com/jakub-g/git-resolve-conflict/blob/base/lib/git-resolve-conflict.sh) to your `.bashrc` (this adds just `git resolve-conflict`)
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

Since those branches can be built separately, a file like `package.json`
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

Details
=======

See `README-extended.md`