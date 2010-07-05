#! /usr/bin/env perl

use inc::Module::Install;

name 'WWW-Fitbit-API';
all_from 'lib/WWW/Fitbit/API.pm';

requires 'Carp';

requires 'Data::Dumper';
requires 'Date::Parse';
requires 'HTTP::Cookies';
requires 'HTTP::Request';
requires 'LWP::UserAgent';
requires 'Log::Log4perl';
requires 'POSIX';
requires 'XML::Simple';

install_script glob('script/*.pl');
auto_install;
WriteAll;
