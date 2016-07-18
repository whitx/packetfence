#!/usr/bin/perl

=head1 NAME

test -

=cut

=head1 DESCRIPTION

test

=cut

use strict;
use warnings;
#
use lib qw(
  /usr/local/pf/lib
  /usr/local/pf/html/captiveportal/lib
  /usr/local/pf/html/pfappserver/lib
);

our $tests;
BEGIN {
    #include test libs
    use lib qw(/usr/local/pf/t);
    #Module for overriding configuration paths
    use setup_test_config;
    $tests = 0;
}

use Selenium::Remote::Driver;
use Selenium::PhantomJS;
use catalyst_runner;
use Test::More tests => $tests + 1;
#This test will running last
use Test::NoWarnings;

SKIP: {
    my $runner = catalyst_runner->new(app => 'pfappserver');
    my ($port, $status) = $runner->start_catalyst_server;
    skip "The Catalyst Service could not be started", $tests if $status ne 'ready';
    my $driver = Selenium::PhantomJS->new;
# Insert code here

    my $base_url = "http://127.0.0.1:$port";
    #$driver->get_page_source;
    $driver->delete_all_cookies();

    $driver->get("${base_url}/configurator/enforcement/");
    print $driver->get_body();
    $driver->find_element("enforcement_vlan", "id")->click; 
    $driver->find_element("//button[\@type='submit']", "xpath")->click;
    print $driver->get_body();
    sleep 2;
    $driver->find_element("ens192", "link")->click;
    $driver->find_element("a.chzn-single.chzn-single-with-drop > span", "css")->click;
    $driver->find_element("input.default", "css")->clear;
    $driver->find_element("input.default", "css")->send_keys("por");
    $driver->find_element("button.btn.btn-primary", "css")->click;
    sleep 2;
    $driver->find_element("(//a[contains(text(),'Ajouter un VLAN')])[2]", "xpath")->click;
    sleep 2;
    $driver->find_element("vlan", "id")->clear;
    $driver->find_element("vlan", "id")->send_keys("131");
    $driver->find_element("ipaddress", "id")->clear;
    $driver->find_element("ipaddress", "id")->send_keys("172.21.131.140");
    $driver->find_element("netmask", "id")->clear;
    $driver->find_element("netmask", "id")->send_keys("255.255.255.128");
    $driver->find_element("vip", "id")->click;
    $driver->find_element("button.btn.btn-primary", "css")->click;
    sleep 2;
    $driver->find_element("(//a[contains(text(),'Ajouter un VLAN')])[2]", "xpath")->click;
    sleep 2;
    $driver->find_element("vlan", "id")->clear;
    $driver->find_element("vlan", "id")->send_keys("132");
    $driver->find_element("ipaddress", "id")->clear;
    $driver->find_element("ipaddress", "id")->send_keys("172.21.132.140");
    $driver->find_element("netmask", "id")->clear;
    $driver->find_element("netmask", "id")->send_keys("255.255.255.128");
    $driver->find_element("a.chzn-single.chzn-single-with-drop > span", "css")->click;
    $driver->find_element("(//li[\@id='type_chzn_o_2'])[3]", "xpath")->click;
    $driver->find_element("button.btn.btn-primary", "css")->click;
    sleep 2;
    $driver->find_element("(//button[\@type='submit'])[2]", "xpath")->click;
    sleep 2;
    $driver->find_element("root_password", "id")->clear;
    $driver->find_element("root_password", "id")->send_keys("inverse");
    sleep 2;
    $driver->find_element("testDatabase", "id")->click;
    sleep 2;
    $driver->find_element("createDatabase", "id")->click;
    sleep 2;
    $driver->find_element("assignUser", "id")->click;
    $driver->find_element("(//button[\@type='submit'])[4]", "xpath")->click;
    sleep 2;
    $driver->find_element("general_domain", "id")->clear;
    $driver->find_element("general_domain", "id")->send_keys("Inverse");
    $driver->find_element("general_hostname", "id")->clear;
    $driver->find_element("general_hostname", "id")->send_keys("test7");
    $driver->find_element("altering_emailaddr", "id")->clear;
    $driver->find_element("altering_emailaddr", "id")->send_keys('ziceo@inverse.ca');
    $driver->find_element("//button[\@type='submit']", "xpath")->click;
    sleep 2;
    $driver->find_element("admin_password", "id")->clear;
    $driver->find_element("admin_password", "id")->send_keys("inverse");
    $driver->find_element("admin_password2", "id")->clear;
    $driver->find_element("admin_password2", "id")->send_keys("inverse");
    $driver->find_element("adminPassword", "id")->click;
    $driver->find_element("(//button[\@type='submit'])[2]", "xpath")->click;
    sleep 2;
    $driver->find_element("//button[\@type='submit']", "xpath")->click;
    sleep 2;
    $driver->quit();
}

=head1 AUTHOR

Inverse inc. <info@inverse.ca>

=head1 COPYRIGHT

Copyright (C) 2005-2016 Inverse inc.

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301,
USA.

=cut

