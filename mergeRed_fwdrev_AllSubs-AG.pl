#!/usr/bin/env perl
# This script merges the two output files of REDItools generated from the sense and antisense BAM files.
# For overlapped sites, only the A-to-G events are retained when the overlapped sites have the A-to-G and T-to-C complementary variants in the two merged files.

use strict;
use warnings;

my $dir = $ARGV[0] || "data";

opendir (DIR, $dir) or die "Cannot open directory $dir: $!\n";
open (LOG, ">$dir.log") or die "Cannot open file $dir.log: $!\n";
foreach my $fwd (sort readdir DIR) {
	# handle filename
	next unless $fwd =~ /\.fwd\.txt$/;
	my $file = $fwd;
	$file =~ s/\.fwd\.txt$//;
	my $rev = $file . ".rev.txt";
	# begin
	warn "Processing $fwd/$rev in $dir\n";
	print LOG "Processing $fwd/$rev in $dir\n";
	my $head = undef;
	my %keys = ();
	# fwd
	my %fwd = ();
	my %fwdline = ();
	open (FWD, "$dir/$fwd") or die "Cannot open file $dir/$fwd: $!\n";
	while (<FWD>) {
		if (/^Region/) {
			$head = $_;
			next;
		}
		my @w = split /\t/;
		$fwd{"$w[0]\t$w[1]"} = $w[7];
		$fwdline{"$w[0]\t$w[1]"} = $_;
		$keys{"$w[0]\t$w[1]"} .= "fwd";
	}
	close FWD;
	# rev
	my %rev = ();
	my %revline = ();
	open (REV, "$dir/$rev") or die "Cannot open file $dir/$rev: $!\n";
	while (<REV>) {
		next if /^Region/;
		my @w = split /\t/;
		$rev{"$w[0]\t$w[1]"} = $w[7];
		$revline{"$w[0]\t$w[1]"} = $_;
		$keys{"$w[0]\t$w[1]"} .= "rev";
	}
	close REV;
	open (MEG, ">$dir/$file.sum.txt") or die "Cannot open file $dir/$file.sum.txt: $!\n";
	open (BTH, ">$dir/$file.fwdrev.txt") or die "Cannot open file $dir/$file.fwdrev.txt: $!\n";
	print MEG $head;
	my $fwdrev_count = 0;
	foreach my $key (sort keys %keys) {
		if ($keys{$key} eq "fwd") {
			print MEG $fwdline{$key};
		} elsif ($keys{$key} eq "rev") {
			print MEG $revline{$key};
		} elsif ($keys{$key} eq "fwdrev") {
			$fwdrev_count++;
			print BTH "# Fwd-Rev-$fwdrev_count\t$key\n";
			print BTH "Fwd:\t" . $fwdline{$key};
			print BTH "Rev:\t" . $revline{$key};
			if ($fwd{$key} eq 'AG' and $rev{$key} eq 'AG') {
				warn "$key: AG (+/-), please check!\n";
				print LOG "$key: AG (+/-), please check!\n";
			} elsif ($fwd{$key} eq 'AG' && $rev{$key} eq 'TC') {
				print MEG $fwdline{$key};
			} elsif ($rev{$key} eq 'AG' && $fwd{$key} eq 'TC') {
				print MEG $revline{$key};
			} else {
				warn "# $key: [^AG]:\n$fwdline{$key}$revline{$key}\n";
				print LOG "# $key: [^AG]:\n$fwdline{$key}$revline{$key}\n";
			}
		} else {
			print LOG "Oops, please check $key!\n";
		}
	}
	close MEG;
	close BTH;
}
closedir DIR;
close LOG;
