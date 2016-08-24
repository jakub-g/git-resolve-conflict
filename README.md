merge-file-ours proof of concept
================================

Say you have multiple git branches and you want to merge always in one direction
between them, and always resolve conflicts in a particular file with a fixed strategy
(say `ours`).

For instance, you have `master` (stable) and `develop` (unstable) branches.
When code is stable you freeze the `master`, and development continues in `develop`,
which is merged to `master` every few weeks.

But then you find our bugs at regression testing stage, you fix them in `master`, and you build.

Sice those branches can be built separately, a file like `package.json`
will be modified in both branches, and there'll be a merge conflict due to `version` field
being changed in both branches.

How to easily resolve the merge conflict in an automated manner in such a situation?
