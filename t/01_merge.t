use Test::More;
use Test::Mojo;
use Test::Deep;

use Mojolicious::Lite;

use strict;
use warnings;

$\ = "\n"; $, = "\t";

get '/extracts' => sub { shift->render(json => { a => { num => 1 }, b => { num => 2 }, c => { num => 3 }, d => { num => 4 }}) };

get '/pageprops' => sub { shift->render(json => { a => { en => 'one' }, b => { en => 'two' }, d => { en => 'four' } }) };

get '/revisions' => sub { shift->render(json => { a => { it => 'uno' }, b => { it => 'due' }, c => { it => 'tre' } }) };

use Mojo::UserAgent;
use Mojo::Promise::Merge;
use Mojo::Util qw/dumper/;

my $t = Test::Mojo->new;

$t->get_ok('/extracts')->status_is(200);

$t->get_ok('/pageprops')->status_is(200);

$t->get_ok('/revisions')->status_is(200);

my $ua = Mojo::UserAgent->new;

my $ref = {
	   "a" => {
		   "en" => "one",
		   "it" => "uno",
		   "num" => 1
		  },
	   "b" => {
		   "en" => "two",
		   "it" => "due",
		   "num" => 2
		  },
	   "c" => {
		   "it" => "tre",
		   "num" => 3
		  },
	   "d" => {
		   "en" => "four",
		   "num" => 4
		  }
	  };

Mojo::Promise->all(
		   $ua->get_p('/extracts'),
		   $ua->get_p('/pageprops'),
		   $ua->get_p('/revisions'),
		  )
    ->then(sub {
	       my $res = Mojo::Promise::Merge::merge(@_);
	       cmp_deeply($res, $ref, 'compare merged');
	       Mojo::IOLoop->stop;
	   })
    ->catch(sub {
		print STDERR @_;
	   });

Mojo::IOLoop->start;

done_testing;
