#!/usr/bin/perl

#
# Author:       Eric Blue - ericblue76@gmail.com
# Project:      Perl Fitbit API - CSV export
# Url:          http://eric-blue.com/projects/fitbit
#

use FitbitClient;
use POSIX;

my $fb = new FitbitClient( config => 'conf/fitbit.conf' );

my $day        = 86400;    # 1 day
my $total_days = 7;

system("mkdir export") if !-e "export";
open( TOTALS_CSV, ">export/totals.csv" ) or die "Can't open CSV file!";

# Weekly CSV header
print TOTALS_CSV
qq{DATE,BURNED,CONSUMED,SCORE,STEPS,DISTANCE,ACTIVE_VERY,ACTIVE_FAIR,ACTIVE_LIGHT,SLEEP_TIME,AWOKEN};
print TOTALS_CSV "\n";

for ( my $i = 0 ; $i < $total_days ; $i++ ) {
    $previous_day = strftime( "%F", localtime( time - $day ) );
    print "Getting data for $previous_day ...\n";

    print TOTALS_CSV $previous_day . ",";
    print TOTALS_CSV $fb->total_calories($previous_day)->{burned} . ",";
    print TOTALS_CSV $fb->total_calories($previous_day)->{consumed} . ",";
    print TOTALS_CSV $fb->total_active_score($previous_day) . ",";
    print TOTALS_CSV $fb->total_steps($previous_day) . ",";
    print TOTALS_CSV $fb->total_distance($previous_day) . ",";

    my $ah = $fb->total_active_hours($previous_day);
    print TOTALS_CSV $ah->{very} . ",";
    print TOTALS_CSV $ah->{fairly} . ",";
    print TOTALS_CSV $ah->{lightly} . ",";

    my $st = $fb->total_sleep_time($previous_day);
    print TOTALS_CSV $st->{hours_asleep} . ",";
    print TOTALS_CSV $st->{wakes} . "\n";

    $day += 86400;

}

close(TOTALS_CSV);

# TODO CSV export for daily/intraday (5-minute) intervals
