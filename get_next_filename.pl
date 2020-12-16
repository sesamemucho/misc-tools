#!/usr/bin/perl --
# get_next_filename - Get the next version of a pathname
# Copyright (C) 2020 Bob Forgey

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

use warnings;
use strict;
use File::Glob ':glob';
use File::Basename;
use Getopt::Long;
use POSIX;

my $usage =<<EOF;
Given a pathname and an extension , get the next version:

 For example, given

    $0 dirname/foo bar

  If dirname/foo*.bar doesn't exist, return dirname/foo-00.bar
  else if dirname/foo.bar exists, return dirname/foo-01.bar
  else if dirname/fooXXX.bar exists and the XXX doesn't look like a version number, die
  else if dirname/foo-dd.bar exists, return dirname/foo-nn.bar, where nn = dd+1

EOF

my $date = 0;
my $result = GetOptions(
    'date' => \$date);

die "Error from GetOptions\n" if !$result;
die "Need exactly one argument\n\n$usage\n" unless $#ARGV == 0;

my $base;
my $ext;

if ($ARGV[0] =~ m/\./)
{
    ($base, $ext) = ($ARGV[0] =~ m/^(.*)(\.[^.]*)/);
}
else
{
    $base = $ARGV[0];
    $ext = '';
}

if ($date)
{
    $base .= '_' . POSIX::strftime("%y%m%d", localtime());
}

#print "base is $base, extension is $ext\n";

my @flist = bsd_glob("${base}*$ext", GLOB_TILDE);

if (scalar @flist == 0)
{
    print "${base}-00$ext\n";
    exit 0;
}

my $last_fname = pop @flist;
my $basename = basename($last_fname, $ext);

#print "flist is: ", join(',', @flist), "\n";
#print "last_fname is: \"$last_fname\"\n";
#print "basename is: \"$basename\"\n";

if ($last_fname eq "${base}$ext")
{
    print "${base}-01$ext\n";
}
elsif ($basename =~ m/.*(\d\d)$/)
{
    my $id = $1;
    printf "%s-%02d%s\n", $base, $id+1, $ext;
}
else
{
    die "Unrecogized name \"$last_fname\"\n";
}

exit 0;
