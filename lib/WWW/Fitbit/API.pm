package WWW::Fitbit::API;

#
# Author:       Eric Blue - ericblue76@gmail.com
# Project:      Perl Fitbit API
# Url:          http://eric-blue.com/projects/fitbit
#

use strict;
use warnings;

use Carp;
use Data::Dumper;
use Date::Parse;
use HTTP::Cookies;
use HTTP::Request;
use LWP::UserAgent;
use Log::Log4perl qw(:easy);
use POSIX;
use XML::Simple;

use vars qw( $VERSION );
$VERSION = '0.1';

#################################################################
# Title         : new (public)
# Usage         : my $fb = WWW::Fitbit::API->new();
# Purpose       : Constructor
# Parameters    : user_id (url profile), uid, uis, sid (cookies)
# Returns       : Blessed class

sub new {

    my $class  = shift;
    my $self   = {};
    my %params = @_;

    $self->{_ua} = LWP::UserAgent->new();
    $self->{_ua}->agent("FitBit Perl API/1.0");

    bless $self, $class;

    # Init logger
    Log::Log4perl->init("conf/logger.conf");
    $self->{_logger} = get_logger();

    if ( defined $params{config} ) {
        my $config = $self->_load_fitbit_config( $params{config} );
        $self->{_uis}     = $config->{'uis'};
        $self->{_uid}     = $config->{'uid'};
        $self->{_sid}     = $config->{'sid'};
        $self->{_user_id} = $config->{'user_id'};
    }
    else {
        my @required_params = qw[uis uid sid user_id];
        foreach (@required_params) {
            confess "$_ is a required parameter!"
              if !defined $params{$_};
        }
        $self->{_uis}     = $params{'uis'};
        $self->{_uid}     = $params{'uid'};
        $self->{_sid}     = $params{'sid'};
        $self->{_user_id} = $params{'user_id'};
    }

    $self->_init_cookies();

    $self;
}

#################################################################
# Title         : _load_fitbit_config (private)
# Usage         : $self->_load_fitbit_config($filename)
# Purpose       : Load config file from disk (Perl variable format)
# Parameters    : Filename = path to fitbit.conf
# Returns       : evaled hashref with config values

sub _load_fitbit_config {

    my $self = shift;
    my ($filename) = @_;

    $/ = "";
    open( CONFIG, "$filename" ) or confess "Can't open config $filename!";
    my $config_file = <CONFIG>;
    close(CONFIG);
    undef $/;

    my $config = eval($config_file) or confess "Invalid config file format!";

    return $config;

}

#################################################################
# Title         : total_calories (public)
# Usage         : $self->total_calories($date)
# Purpose       : Displays total calories burned and consumed
# Parameters    : date = YYYY-MM-DD (optional; default = today)
# Returns       : Hash ref; keys = burned, consumed
#                 values = decimal (calories)

sub total_calories {

    my $self = shift;
    my ($date) = @_;

    #my $total = 0;
    #$total += $_->{value} foreach ( $self->get_calories_log($date) );

    my @result = $self->_parse_graph_xml( "calorie_historical", $date );

    return $result[0];

}

#################################################################
# Title         : get_calories_log (public)
# Usage         : $self->get_calories_log($date)
# Purpose       : Displays total calories in 5min intervals
# Parameters    : date = YYYY-MM-DD (optional; default = today)
# Returns       : Hash ref; keys = time, value
#                 values = YYYY-MM-DD HH:MM[A|P]M, decimal

sub get_calories_log {

    my $self = shift;
    my ($date) = @_;

    return $self->_parse_graph_xml( "calorie", $date );

}

#################################################################
# Title         : total_active_score (public)
# Usage         : $self->total_active_store($date)
# Purpose       : Displays total active score
# Parameters    : date = YYYY-MM-DD (optional; default = today)
# Returns       : decimal (score)

sub total_active_score {

    my $self = shift;
    my ($date) = @_;

    my @result = $self->_parse_graph_xml( "active_score_historical", $date );

    return $result[0];

}

#################################################################
# Title         : get_active_score_log (public)
# Usage         : $self->get_active_score_log($date)
# Purpose       : Displays total active score in 5min intervals
# Parameters    : date = YYYY-MM-DD (optional; default = today)
# Returns       : Hash ref; keys = time, value
#                 values = YYYY-MM-DD HH:MM[A|P]M, decimal

sub get_active_score_log {

    my $self = shift;

    my ($date) = @_;

    return $self->_parse_graph_xml( "active_score", $date );

}

#################################################################
# Title         : total_steps (public)
# Usage         : $self->total_steps($date)
# Purpose       : Displays total steps
# Parameters    : date = YYYY-MM-DD (optional; default = today)
# Returns       : decimal (steps)

sub total_steps {

    my $self = shift;
    my ($date) = @_;

    my @result = $self->_parse_graph_xml( "steps_historical", $date );

    return $result[0];

}

#################################################################
# Title         : get_step_log (public)
# Usage         : $self->get_step_log($date)
# Purpose       : Displays total steps in 5min intervals
# Parameters    : date = YYYY-MM-DD (optional; default = today)
# Returns       : Hash ref; keys = time, value
#                 values = YYYY-MM-DD HH:MM[A|P]M, decimal

sub get_step_log {

    my $self = shift;

    my ($date) = @_;

    return $self->_parse_graph_xml( "steps", $date );

}

#################################################################
# Title         : get_weight_log (public)
# Usage         : $self->get_weight_log($date)
# Purpose       : Displays weight in 1d intervals
# Parameters    : date = YYYY-MM-DD (optional; default = today)
# Returns       : Hash ref; keys = time, value
#                 values = YYYY-MM-DD HH:MM[A|P]M, decimal

sub get_weight_log {

    my $self = shift;

    my ($date) = @_;

    return $self->_parse_graph_xml( "weight_historical", $date );

}

#################################################################
# Title         : get_sleep_log (public)
# Usage         : $self->get_sleep_log($date)
# Purpose       : Displays total sleep in 1min intervals
# Parameters    : date = YYYY-MM-DD (optional; default = today)
# Returns       : Hash ref; keys = time, value
#                 values = YYYY-MM-DD HH:MM[A|P]M, decimal

sub get_sleep_log {

    my $self = shift;

    my ($date) = @_;

    return $self->_parse_graph_xml( "sleep", $date );

}

#################################################################
# Title         : total_distance (public)
# Usage         : $self->total_distance($date)
# Purpose       : Displays total distance travel in miles
# Parameters    : date = YYYY-MM-DD (optional; default = today)
# Returns       : float (miles)

sub total_distance {

    my $self = shift;
    my ($date) = @_;

    my @result = $self->_parse_graph_xml( "distance_historical", $date );

    return $result[0];

}

#################################################################
# Title         : total_active_hours (public)
# Usage         : $self->total_active_hours($date)
# Purpose       : Displays total activity breakdown
# Parameters    : date = YYYY-MM-DD (optional; default = today)
# Returns       : Hash ref; keys = very, fairly, lightly
#                 values = hours as floats (e.g. 3.0)

sub total_active_hours {

    my $self = shift;
    my ($date) = @_;

    my @result = $self->_parse_graph_xml( "active_hours_historical", $date );

    return $result[0];

}

#################################################################
# Title         : total_active_score (public)
# Usage         : $self->total_active_store($date)
# Purpose       : Displays total active score
# Parameters    : date = YYYY-MM-DD (optional; default = today)
# Returns       : decimal (score)

sub total_sleep_time {

    my $self = shift;
    my ($date) = @_;

    my @r1 = $self->_parse_graph_xml( "sleep_time_historical", $date );
    my $hours_asleep = $r1[0];

    my @r2 = $self->_parse_graph_xml( "wakeup_historical", $date );
    my $wakes = $r2[0];

    my $result = { hours_asleep => $hours_asleep, wakes => $wakes };

    return $result;

}

#################################################################
# Title         : _check_date_format (private)
# Usage         : $self->_check_date_format($date)
# Purpose       : Verify valid date format is supplied
# Parameters    : date
# Returns       : 1 (true) ; confess on error

sub _check_date_format {

    my $self = shift;
    my ($date) = @_;

    # Very basic regex to check date format
    if ( $date !~ /(\d{4})-(\d{2})-(\d{2})/ ) {
        confess "Invalid date format [$date].  Expected (YYYY-MM-DD)";
    }

    return 1;
}

#################################################################
# Title         : _get_date (private)
# Usage         : $self->_get_date()
# Purpose       : Returns default date for methods where date
#                 parameter is not supplied; Defaults to today
# Parameters    : n/a
# Returns       : Date string (format = YYYY-MM-DD)

sub _get_date {

    my $self = shift;

    # Default to today's date
    my $date = strftime( "%F", localtime );

    return $date;

}

#################################################################
# Title         : _init_cookies (private)
# Usage         : $self->_init_cookies()
# Purpose       : Initializes cookis for required sid, uid, & uis
# Parameters    : url = base fitbit URL + graph-specific query
# Returns       : 1 (true)

sub _init_cookies {

    my $self = shift;

    my $cookie_jar = HTTP::Cookies->new;
    $cookie_jar->set_cookie( 1, 'sid', $self->{_sid}, '/', 'www.fitbit.com', 80,
        0, 0, 3600, 0 );
    $cookie_jar->set_cookie( 1, 'uid', $self->{_uid}, '/', 'www.fitbit.com', 80,
        0, 0, 3600, 0 );
    $cookie_jar->set_cookie( 1, 'uis', $self->{_uis}, '/', 'www.fitbit.com', 80,
        0, 0, 3600, 0 );
    $self->{_ua}->cookie_jar($cookie_jar);

    return 1;

}

#################################################################
# Title         : _request_http (private)
# Usage         : $self->_request_http($url)
# Purpose       : Performs HTTP GET on requested URL
# Parameters    : url = base fitbit URL + graph-specific query
# Returns       : HTTP response content (XML)

sub _request_http {

    my ( $self, $url ) = @_;

    $self->{_logger}->debug("URL = $url");

    # Note that user agent also uses cookie jar created on initialization
    my $request = HTTP::Request->new('GET', $url);
    my $response = $self->{_ua}->request($request);

    if ( !$response->is_success ) {
        $self->{_logger}
          ->info( "HTTP status = ", Dumper( $response->status_line ) );
        confess "Couldn't get graph data; reason = HTTP status ($response->{_rc})!";
    }

    return $response->content;

}

#################################################################
# Title         : _request_graph_xml (private)
# Usage         : $self->_request_graph_xml($graph_type, $date)
# Purpose       : Build URL based on graph type and fetch XML
# Parameters    : graph_type = [see $type_map for valid values]
#                 date = YYYY-MM-DD
# Returns       : XML string

sub _request_graph_xml {

    my $self = shift;
    my ( $graph_type, $date ) = @_;

    my $type_map = {

        # intraday data in 5 min intervals
        'active_score' => 'intradayActiveScore',
        'calorie'      => 'intradayCaloriesBurned',
        'sleep'        => 'intradaySleep',
        'steps'        => 'intradaySteps',

        # historical data with aggregate info
        'active_hours_historical' => 'minutesActive',
        'active_score_historical' => 'activeScore',
        'calorie_historical'      => 'caloriesInOut',
        'distance_historical'     => 'distanceFromSteps',
        'steps_historical'        => 'stepsTaken',
        'sleep_time_historical'   => 'timeAsleep',
        'wakeup_historical'       => 'timesWokenUp',
        'weight_historical'       => 'weight'
    };

    if ( !defined $type_map->{$graph_type} ) {
        confess "$graph_type is not a valid graph type!";
    }

    # TODO Add methods for sleep; need to solve day-boundary problem (see python code)

    # TODO Add second parameter (duration in days) to fetch multiple days worth of data
    # in a single request (avoiding multiple HTTP Requests).  This would change duration
    # from 1d to 1m

    # TODO Add support for getting weight info

    my $base_params = {
        userId      => $self->{_user_id},
        type        => $type_map->{$graph_type},
        period      => "1d",
        dataVersion => "2108",
        version     => "amchart",
        chart_type  => "column2d",
        dateTo      => $date
    };

    my $query_string = join '&',
      map { "$_=$base_params->{$_}" } keys %{$base_params};

    my $base_graph_url = "http://www.fitbit.com/graph/getGraphData";

    my $url = "$base_graph_url" . "?" . $query_string;
    my $xml = $self->_request_http($url);

    # Strip leading whitespace for proper parsing
    $xml =~ s/^\s+//gm;

    $self->{_logger}->debug("XML = $xml");

    return $xml;

}

#################################################################
# Title         : _parse_graph_xml (private)
# Usage         : $self->_parse_graph_xml($graph_type, $date)
# Purpose       : Parses graph XML using XMLIn
# Parameters    : graph_type = [see $type_map for valid values]
#                 date = YYYY-MM-DD
# Returns       : XML string

sub _parse_graph_xml {

    my $self = shift;
    my ( $graph_type, $date ) = @_;

    defined $date ? $self->_check_date_format($date) : $date =
      $self->_get_date();
    $self->{_logger}->info("Getting $graph_type for date $date");

    my $xml = $self->_request_graph_xml( $graph_type, $date );
    my $graph_data;

    eval { $graph_data = XMLin( $xml, keyattr => [] ); };
    if ($@) {
        confess "$$: XMLin() died: $@\n";
    }

    my @entries;

    # Parsing for similar intraday graph types; treat values an array
    if ( grep( /^$graph_type$/, qw[calorie activescore steps] ) ) {

        foreach ( @{ $graph_data->{data}{chart}{graphs}{graph}{value} } ) {
            next if !defined $_->{description};

            # Sample description: "7 calories burned from 9:40pm to 9:45pm"
            my @v = split / /, $_->{description};
            my $log_time =
              strftime( "%I:%M%p", localtime( str2time( $v[4] ) ) );
            push( @entries,
                { time => "$date $log_time", value => $_->{content} } );
        }
    }

    # Parsing for sleep; unlike other intraday logs this crosses 24-hour day boundaries
    # TODO Populate date after we figure out whether sleep record crosses a day boundary

    if ( $graph_type eq "sleep" ) {

        foreach ( @{ $graph_data->{data}{chart}{graphs}{graph}{value} } ) {
            next if !defined $_->{description};

            # Sample description: "awake at 11:12pm"
            my @v = split / /, $_->{description};

            # 'awake' or 'asleep'
            my $sleep_status = $v[0];
            my $log_time =
              strftime( "%I:%M%p", localtime( str2time( $v[2] ) ) );

            # Note: $log_time is only the timestamp right now and doesn't yet include date
            push( @entries, { time => "$log_time", value => $sleep_status } );
        }

    }

    # Parsing for historical graphs: each graph type serializes slightly different
    if ( $graph_type =~ /_historical/ ) {
        if ( $graph_type eq "calorie_historical" ) {

            # Sample description: "2690 calories burned on Sat, May 1"
            my @v1 = split / /,
              $graph_data->{data}{chart}{graphs}{graph}[0]{value}{description};
            my $calories_burned = $v1[0];

            # Sample description: "2102 calories eaten on Sat, May 1"
            my @v2 = split / /,
              $graph_data->{data}{chart}{graphs}{graph}[1]{value}{description};
            my $calories_consumed = $v2[0];

            push( @entries,
                { burned => $calories_burned, consumed => $calories_consumed }
            );
        }
        if ( $graph_type eq "active_score_historical" ) {

            # Sample description: "598 on Sat, May 1"
            my @v = split / /,
              $graph_data->{data}{chart}{graphs}{graph}{value}{description};
            my $total_score = $v[0];
            push( @entries, $total_score );
        }
        if ( $graph_type eq "sleep_time_historical" ) {

            # Sample description: "7.37 hours asleep on Sat, May 1"
            my @v = split / /,
              $graph_data->{data}{chart}{graphs}{graph}{value}{description};
            my $total_sleep = $v[0];
            push( @entries, $total_sleep );

        }
        if ( $graph_type eq "wakeup_historical" ) {

            # Sample description: "awoke 6 times on Sat, May 1"
            my @v = split / /,
              $graph_data->{data}{chart}{graphs}{graph}{value}{description};
            my $total_wakes = $v[1];
            push( @entries, $total_wakes );

        }
        if ( $graph_type eq "weight_historical" ) {
            # Sample description: "80.5 kg on Mon, Jan 1"
            my @v = split / /,
              $graph_data->{data}{chart}{graphs}{graph}[0]{value}[1]{description};
            my $weight = $v[0];
            $self->{_logger}->debug("weight = $weight");
            push( @entries, $weight );
        }
        if ( $graph_type eq "steps_historical" ) {

            # Sample description: "11,232 steps on Sat, May 1"
            my @v = split / /,
              $graph_data->{data}{chart}{graphs}{graph}{value}{description};
            my $total_steps = $v[0];
            push( @entries, $total_steps );
        }
        if ( $graph_type eq "distance_historical" ) {

            # Sample description: "4.32 miles travelled on Sat, May 1"
            my @v = split / /,
              $graph_data->{data}{chart}{graphs}{graph}{value}{description};
            my $total_distance = $v[0];
            push( @entries, $total_distance );
        }
        if ( $graph_type eq "active_hours_historical" ) {

            # Sample description: ".9 hours lightly active on Sat, May 1"
            my @v1 = split / /,
              $graph_data->{data}{chart}{graphs}{graph}[0]{value}{description};
            my $lightly_active = $v1[0];

            # Sample description: "1.23 hours fairly active on Sat, May 1"
            my @v2 = split / /,
              $graph_data->{data}{chart}{graphs}{graph}[1]{value}{description};
            my $fairly_active = $v2[0];

            # Sample description: "1.5 hours very active on Sat, May 1"
            my @v3 = split / /,
              $graph_data->{data}{chart}{graphs}{graph}[2]{value}{description};
            my $very_active = $v3[0];

            push(
                @entries,
                {
                    lightly => $lightly_active,
                    fairly  => $fairly_active,
                    very    => $very_active
                }
            );

        }

    }

    return @entries;

}

1;

__END__


=head1 NAME

WWW::Fitbit::API - OO Perl API used to fetch fitness data from fitbit.com

=head1 SYNOPSIS

Sample Usage:

    use WWW::Fitbit::API;

    my $fb = WWW::Fitbit::API->new(
        # Available from fitbit profile URL
        user_id => "XXXNSD",
        # Populated by cookie
        sid     => "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX",
        uid     => "12345",
        uis     => "XXX%3D"
    );

    OR

    my $fb = WWW::Fitbit::API->new(config => 'conf/fitbit.conf');

    # No date defaults to today
    my @log = $fb->get_calories_log();
    foreach (@log) {
        print "time = $_->{time} : calories = $_->{value}\n";
    }

    print "calories = " . $fb->total_calories("2010-05-03") . "\n";
    print "activescore = " . $fb->total_active_score("2010-05-03") . "\n";
    print "steps = " . $fb->total_steps("2010-05-03") . "\n";

=head1 DESCRIPTION


C<WWW::Fitbit::API> provides an OO API for fetching fitness data from fitbit.com.
Currently there is no official API, however data is retrieved using XML feeds
that populate the flash-based charts.

Intraday (5min and 1min intervals) logs are provide for:

 - calories burned
 - activity score
 - steps taken
 - sleep activity (every 1 min)

Historical (aggregate) info is provided for:

 - calories burned / consumed
 - activity score
 - steps taken
 - distance travels (miles)
 - sleep (total time in hours, and times awoken)

=head1 METHODS

See method comments for detailed API info:

Note that all detailed log methods (get_*) and historical (total_*)
accept a single data parameter (format = YYYY-MM-DD).  If no date
is supplied, today's date will be used.

=head1 EXAMPLE CODE

See test_client.pl and dump_csv.pl

=head1 KNOWN_ISSUES

At this time, if you attempt to tally the intraday (5min) logs for
the total daily number, this number will NOT match the number from
the total_*_ API call.  This is due to the way that FitBit feeds the
intraday values via XML to the flash-graph chart.  All numbers are
whole numbers, and this rounding issue causes the detailed log
tally to be between 10-100 points higher.

For example:

    # Calling total = 2122
    print "Total calories burned = " . $fb->total_calories()->{burned} . "\n";

    # Tallying total from log entries = 2157
    my $total = 0;
    $total += $_->{value} foreach ( $fb->get_calories_log($date) );

=head1 AUTHOR

Eric Blue <ericblue76@gmail.com> - http://eric-blue.com

=head1 COPYRIGHT

Copyright (c) 2010 Eric Blue. This program is free
software; you can redistribute it and/or modify it under the same terms
as Perl itself.

=cut

