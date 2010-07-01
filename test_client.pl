#!/usr/bin/perl

# $Id: test_client.pl,v 1.5 2010-05-12 03:45:31 ericblue76 Exp $
#
# Author:       Eric Blue - ericblue76@gmail.com
# Project:      Perl Fitbit API - client test script
# Url:          http://eric-blue.com/projects/fitbit
#

use FitbitClient;

my $fb = new FitbitClient( config => 'conf/fitbit.conf' );

print "Total calories burned = " . $fb->total_calories()->{burned} . "\n";
print "Total calories consumed = " . $fb->total_calories()->{consumed} . "\n";

#my @log = $fb->get_calories_log("2010-05-01");
#foreach (@log) {
#    print "time = $_->{time} : calories = $_->{value}\n";
#}
#

print "activescore = " . $fb->total_active_score("2010-05-01") . "\n";
print "steps = " . $fb->total_steps("2010-05-01") . "\n";
print "distance walked = " . $fb->total_distance("2010-05-01") . "\n";

my $ah = $fb->total_active_hours("2010-05-01");
print "active hours = very[$ah->{very}], fair[$ah->{fairly}], light[$ah->{lightly}]\n";

my $st = $fb->total_sleep_time("2010-05-01");
print "sleep = hours[$st->{hours_asleep}], wakes[$st->{wakes}]\n";
