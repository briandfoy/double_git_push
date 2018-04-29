# double_git_push

I like to keep my repos in at least two different services. If one is
down or disappears I have another repo somewhere else (looking at you
Google). This program sets up a remote named "all" that uses GitHub as
the main source but pushes to GitHub and Bitbucket at the same time.
master can track this branch so that pushing master pushes to two
different repos.
