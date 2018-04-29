use v5.24;
use strict;
use warnings;
use feature qw(signatures);
no warnings qw(experimental::signatures);

use Data::Dumper;

=encoding utf8

=head1 NAME

=head1 SYNOPSIS

	# create repos of the same name in GitHub and Bitbucket

	# inside your GitHub clone (where GitHub is origin)
	# you need Perl v5.24 and Mojolicious
	% git_all_config.pl

=head1 DESCRIPTION

I like to keep my repos in at least two different services. If one is
down or disappears I have another repo somewhere else (looking at you
Google). This program sets up a remote named "all" that uses GitHub as
the main source but pushes to GitHub and Bitbucket at the same time.
master can track this branch so that pushing master pushes to two
different repos.

I have to keep using this because a repo does not track the local git
config. If I get a fresh clone I need to get this again.

If something bad happens with the secondary repos, I simply delete
them, recreate them, and push again. If they get out of sync I don't try
to reconcile it. GitHub is the authoritative repo.

=head2 Clone your GitHub project

This program expects that to be the "origin" remote.

=head2 Get a BitBucket API key and secret

Set BITBUCKET_API_KEY and BITBUCKET_API_SECRET environment variables.
This program uses those to get an OAuth token. Go to your settings and
find the OAuth panel. Ensure that you add a callback URL even though
its not a required field. I used "http://www.example.com".

=head2 Prior Art

=over 4

=item * https://gist.github.com/bjmiller121/f93cd974ff709d2b968f

=item * Pushing to multiple git repos - http://alexarmstrong.net/2015/01/pushing-to-multiple-git-repos

=item * Git - Pushing code to two remotes - https://stackoverflow.com/q/14290113/2766176

=item * pull/push from multiple remote locations - https://stackoverflow.com/q/849308/2766176

=item * Pushing to Multiple Remote Repositories Using Git - http://caseyscarborough.com/blog/2013/08/25/pushing-to-multiple-remotes-using-git/

=item * Git push to multiple remotes - http://blog.deadlypenguin.com/blog/2016/05/02/git-push-multiple-remotes/

=back

=head1 TO DO

=over 4

=item * Automatically import to Bitbucket with just a GitHub project

=item * Add GitLab to this. Push to three places!

=item * restore the original config if something doesn't go right

=back

=head1 SOURCE AVAILABILITY

This source is in GitHub:

	https://github.com/briandfoy/double_git_push

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2018, brian d foy <bdfoy@cpan.org>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the Artistic License 2.0.

=cut

######################################################################
# Current remotes setup
# It might be half setup already
# Don't disturb what is already there
my $output = qx/git remote show/;
my @remotes = $output =~ /(\S+)/g;

my %remotes;
foreach my $remote ( @remotes ) {
	my $output = qx/git remote show $remote/;
	my( $fetch_url ) = $output =~ m/Fetch+ \s URL: \s+ (\S+)/x;

	say "$remote -> $fetch_url";
	$remotes{$remote} = $fetch_url;
	}

# backup the .git/config file in case this messes up
use File::Copy qw(copy);
my $config_file = '.git/config';
copy( $config_file, $config_file . '.bak' );

######################################################################
# GitHub
# The GitHub project has to already exist
# is this a GitHub thingy? If not bail out.
unless( $remotes{origin} =~ m/github/ ) {
	die "origin is not a github address. Manual attention required.\n";
	}

my( $project ) = $remotes{origin}
	=~ m{\A (?: https?:// | git\@ ) github\.com [:/] (.*?) \.git }x;
say "GitHub project is: $project";

######################################################################
# BitBucket
# The bitbucket project can already exist but I want to automate
# its import if it does not.
=pod

# get project and check bitbucket?
# https://gist.github.com/tuvistavie/f49da483a5b59dec9484b42ad5d25caa
# https://designhammer.com/blog/easily-migrate-git-repositories-bitbucket
# curl --user USER:PASSWORD https://api.bitbucket.org/1.0/repositories/ --data name=$repo --data is_private=true --data owner=designhammer
# git push --mirror git@bitbucket.org:designhammer/$repo.git


curl https://bitbucket.org/repo/import?owner=txxxxh
	-H 'Pragma: no-cache'
	-H 'Origin: https://bitbucket.org'
	-H 'Accept-Encoding: gzip, deflate'
	-H 'Accept-Language: en-US,en;q=0.8,en-GB;q=0.6,ml;q=0.4'
	-H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.71 Safari/537.36'
	-H 'Content-Type: application/x-www-form-urlencoded'
	-H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'
	-H 'Cache-Control: no-cache'
	-H 'Referer: https://bitbucket.org/repo/import?owner=txxxxxh'
	-H 'Cookie: optimizelyEndUserId=oexxxxxxxxxx643798; __ar_v4=3coookies-form'
	-H 'Connection: keep-alive'
	-H 'DNT: 1'
	--data 'source_scm=git&source=source-git&goog_project_name=&goog_scm=svn&sourceforge_project_name=&sourceforge_mount_point=&sourceforge_scm=svn&codeplex_project_name=&codeplex_scm=svn&url=" + url + ".git&auth=on&username=nyyyyyys&password=Gvvvvv&owner=36vvvv2&name=" + name + "&description=&is_private=on&forking=no_forks&no_forks=True&no_public_forks=True&has_wiki=on&language=php&csrfmiddlewaretoken=MErrrrrrrrrOZ91r&scm=git'
	--compressed";

POST /repo/import HTTP/1.1
Host: bitbucket.org:443
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8
Accept-Encoding: gzip, deflate, br
Accept-Language: en-US,en;q=0.9
Content-Type: application/x-www-form-urlencoded
Cookie: NEW_VISITOR=new; _evga_3efd=018581e265934a30.; csrftoken=aRY4VlwZSfs3lkfAdEof5BbuLZ80g84PwbXkcQOZ9XP2LC2dEy38pyEQXJ5cSpwy; bb_session=5cr8pq3giu588ij0qqnltcmua21hx0gh; ajs_group_id=null; ajs_user_id=%22557058%3A566306e2-889b-4a5f-9d5f-b41193f7e85e%22; ajs_anonymous_id=%22e1000457-e112-4888-85e7-265d57387430%22; recently-viewed-repos_briandfoy=b92e7142-7a97-4dfb-8400-4d578c8a38ac%2Ce11c1545-92bf-4119-96c4-4a21f96a748e%2C1347d0cb-c743-4750-9a42-65f940c09561
DNT: 1
Origin: https://bitbucket.org
Referer: https://bitbucket.org/repo/import
Upgrade-Insecure-Requests: 1
User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.139 Safari/537.36

owner=3230758 (briandfoy)
project=
id_project_name=
id_project_key=
name=
is_private - checkbox
readme_type=none
scm=git
id_forking=allow_forks
no_forks=False
has_issues=
language=
# <input type='hidden' name='csrfmiddlewaretoken' value='iIQ86orozObe7ng8U4pTy2i7Jdc00uNYE2PonTJoQwydxF3LlY4MSZLtVX9cCLfH' />
csrfmiddlewaretoken=  need to get with Mojo

=cut

# check if it's already in bitbucket. If it's not and the remote
# bitbucket does not already exist, drive on.
# The bitbucket project slug should be the same as the GitHub one.
my $bitbucket = it_is_in_bitbucket( $project );
if( ! exists $remotes{bitbucket} or ! $bitbucket ) {
	# does it already exist in bitbucket?
	my $data;
	unless( $bitbucket ) {
		say "It's not in BitBucket";
		# can we import by API?
		$bitbucket = import_from_github_to_bitbucket( $project );
		die "Could not import into BitBucket!\n";
		}

	my $clone_url = (
		grep { $_->{name} eq 'ssh' }
			$bitbucket->{links}{clone}->@*
		)[0]{href};
	die "No bitbucket remote address!\n" unless $clone_url;

	system qw/git remote add bitbucket/, $clone_url;
	$remotes{bitbucket} = $clone_url;
	}
else {
	say "Bitbucket remote exists: $remotes{bitbucket}";
	}

sub import_from_github_to_bitbucket ( $project ) {
	# need GitHub https address
	# https://github.com/briandfoy/app-ypath.git
	my $github_address = 'https://github.com/$project';

return;  # does not work yet

	# wait a bit for the repository to input but eventually give up.
	my $data;
	foreach ( 0 .. 5 ) {
		state $interval = 1;
		$data = it_is_in_bitbucket( $project );
		last if $data;
		say "Sleeping for $interval seconds";
		sleep( $interval *= 2 );
		}

	return unless $data;
	$data;
	}

sub it_is_in_bitbucket ( $project ) {
	unless( $project =~ m|/| ) {
		warn "Project name should be user_name/slug. Got [$project]\n";
		return;
		}

	my $tx = bitbucket_ua()->get(
		"https://api.bitbucket.org/2.0/repositories/$project"
			=> { 'Authorization' => "Bearer " . get_bitbucket_token() }
		);
	unless( $tx->res->is_success ) {
		my $error = eval{ $tx->res->json->{error}{message} };
		if( $error ) {
			say "BitBucket: $error";
			}
		return;
		}

	my $perl = $tx->res->json;
	}

sub get_bitbucket_token ( $key = $ENV{BITBUCKET_API_KEY}, $secret = $ENV{BITBUCKET_API_SECRET} ) {
	state $token;
	state $expires = time - 1;

	if( defined $token && time <= $expires ) {
		return $token
		}

	my $tx = bitbucket_ua()->post(
		"https://$key:$secret\@bitbucket.org/site/oauth2/access_token"
			=> form => { grant_type => 'client_credentials' }
		);
	unless( $tx->res->is_success ) {
		say "Failed to get BitBucket token!";
		say $tx->res->body;
		return;
		}

	my $perl = $tx->res->json;

	$expires = $perl->{expires_in};
	$token   = $perl->{access_token};
	}

sub bitbucket_ua () {
	state $rc = require Mojo::UserAgent;
	unless( $rc ) {
		die "Install Mojolicious to use this program\n\t$ cpan Mojolicious\n";
		}

	state $ua = Mojo::UserAgent->new;

	$ua;
	}

######################################################################
# All remote
# Now that we have multiple remotes we can add them all as pushurls
unless( exists $remotes{all} ) {
	system qw/git remote add all/, $remotes{origin};
	system qw/git remote set-url --push all/, $remotes{origin};
	system qw/git remote set-url --add --push all/, $remotes{bitbucket};
	}
else {
	say "all remote exists: $remotes{all}";
	}

######################################################################
# Final setup
# Make master use the "all" url. It fetches from GitHub but pushes
# to many other places too.
system qw/git push -u all master/;


######################################################################
# Cleanup
# check everything

print "---- the updated config -----\n";
open my $fh, '<:utf8', $config_file;
print while( <$fh> );
print "-----------------------------";

# haven't done this yet.
# there's a backup file of the old git config

__END__
