package pf::provisioner::opswat;
=head1 NAME

pf::provisioner::opswat add documentation

=cut

=head1 DESCRIPTION

pf::provisioner::opswat

=cut

use strict;
use warnings;
use Moo;
extends 'pf::provisioner';

use pf::util qw(clean_mac);
use WWW::Curl::Easy;
use JSON qw( decode_json );
use XML::Simple;
use Log::Log4perl;
use pf::iplog;
use pf::ConfigStore::Provisioning;
use DateTime::Format::RFC3339;

=head1 Atrributes

=head2 client_id

Client id to connect to the API

=cut

has client_id => (is => 'rw');

=head2 client_secret

Client secret to connect to the API

=cut

has client_secret => (is => 'rw');

=head2 host

Host of the SEPM web API

=cut

has host => (is => 'rw', default => sub { "gears.opswat.com" });

=head2 port

Port to connect to the SEPM web API

=cut

has port => (is => 'rw', default =>  sub { 443 } );

=head2 protocol

Protocol to connect to the SEPM web API

=cut

has protocol => (is => 'rw', default => sub { "https" } );

=head2 access_token

The access token to be authorized on the SEPM web API

=cut

has access_token => (is => 'rw');

=head2 refresh_token

The token to refresh the access token once it expires

=cut

has refresh_token => (is => 'rw');

=head2 agent_download_uri

The URI to download the agent

=cut

has agent_download_uri => (is => 'rw');

# amount of minutes to condider the node as still active with OPSWAT
my $CONNECTION_DELAY = 30;

sub get_refresh_token {
    my ($self) = @_;
    my $logger = Log::Log4perl::get_logger( ref($self) );
    return $self->{'refresh_token'}
}

sub set_refresh_token {
    my ($self, $refresh_token) = @_;
    my $logger = Log::Log4perl::get_logger( ref($self) );
    if (!defined($refresh_token) || $refresh_token eq ''){
        $logger->error("Called set_refresh_token but the refresh token is invalid");
    } 
    else{
        $self->{'refresh_token'} = $refresh_token;
        my $cs = pf::ConfigStore::Provisioning->new;
        $logger->info($self->{'id'});
        $cs->update($self->{'id'}, {refresh_token => $refresh_token});
        $cs->commit();
    }
    
}

sub get_access_token {
    my ($self) = @_;
    my $logger = Log::Log4perl::get_logger( ref($self) );
    return $self->{'access_token'};   
}

sub set_access_token {
    my ($self, $access_token) = @_;
    my $logger = Log::Log4perl::get_logger( ref($self) );
    if (!defined($access_token) || $access_token eq ''){
        $logger->error("Called set_access_token but the access token is invalid.");
    }
    else{
        $self->{'access_token'} = $access_token;
        my $cs = pf::ConfigStore::Provisioning->new;
        $logger->info($self->{'id'});
        $cs->update($self->{'id'}, {access_token => $access_token});
        $cs->commit();
    }
}

sub refresh_access_token {
    my ($self) = @_;
    my $logger = Log::Log4perl::get_logger( ref($self) );
        
    my $refresh_token = $self->get_refresh_token();
    my $curl = WWW::Curl::Easy->new;
    my $url = $self->protocol."://".$self->host.":".$self->port."/o/oauth/token?grant_type=refresh_token&client_id=".$self->client_id."&client_secret=".$self->client_secret."&refresh_token=$refresh_token";
    
    my $response_body = '';
    open(my $fileb, ">", \$response_body);
    $curl->setopt(CURLOPT_URL, $url );
    $curl->setopt(CURLOPT_SSL_VERIFYPEER, 0) ; 
    $curl->setopt(CURLOPT_HEADER, 0);   
    $curl->setopt(CURLOPT_WRITEDATA,$fileb);

    my $curl_return_code = $curl->perform;
    my $curl_info = $curl->getinfo(CURLINFO_HTTP_CODE); # or CURLINFO_RESPONSE_CODE depending on libcurl version

    if ( $curl_return_code != 0 or $curl_info != 200 ) { 
        # Failed to contact the OPSWAT API.;
        $logger->error("Cannot connect to OPSWAT to refresh the token");
        return -1;   
    }
    else{
        
        my $json_response = decode_json($response_body);
        my $access_token = $json_response->{'access_token'};
        $refresh_token = $json_response->{'refresh_token'};
        $self->set_access_token($access_token);
        $self->set_refresh_token($refresh_token);
        $logger->info("Refreshed the token to connect to the OPSWAT API");
    }
}

sub validate_mac_in_opswat {
    my ($self, $mac) = @_;
    my $logger = Log::Log4perl::get_logger( ref($self) );
 
    my $access_token = $self->get_access_token();
    my $curl = WWW::Curl::Easy->new;
    my $url = $self->protocol.'://' . $self->host . ':' .  $self->port . "/o/api/v2.1/devices/$mac?opt=1&access_token=$access_token";
    
    $logger->info($url);

    my $response_body = '';
    open(my $fileb, ">", \$response_body);
    $curl->setopt(CURLOPT_URL, $url );
    $curl->setopt(CURLOPT_SSL_VERIFYPEER, 0) ; 
    $curl->setopt(CURLOPT_HEADER, 0);
    $curl->setopt(CURLOPT_WRITEDATA,$fileb);

    my $curl_return_code = $curl->perform;
    my $curl_info = $curl->getinfo(CURLINFO_HTTP_CODE); # or CURLINFO_RESPONSE_CODE depending on libcurl version

    $logger->info($curl_info);
    $logger->info($response_body); 
    
    if ( $curl_info == 401 ) { 
        $logger->error("Unable to contact OPSWAT on url ".$url);
        return -1;   
    }
    elsif($curl_info != 200){
        return -1;
    } 
    else { 
        my $json_response = decode_json($response_body);
        return $self->check_active($mac, $json_response);
    } 
}

sub check_active {
    my ($self, $mac, $json_response) = @_;
    my $logger = Log::Log4perl::get_logger( ref($self) );

    my $f = DateTime::Format::RFC3339->new();
    unless(defined($json_response->{last_seen})){
        $logger->info("Node $mac not found in the OPSWAT provisioner");
        return 0;
    }
    my $last_seen = $f->parse_datetime( $json_response->{last_seen} );

    my $minutes_last_seen = ((time() - $last_seen->epoch)/60);

    if($minutes_last_seen > $CONNECTION_DELAY){
        $logger->info("$mac doesn't seem to be active with OPSWAT anymore ($minutes_last_seen is more than $CONNECTION_DELAY minutes ago)");
        return 0;
    }
    else{
        $logger->info("$mac is still active with OPSWAT ($minutes_last_seen is less than $CONNECTION_DELAY minutes ago)");
        return 1;
    }
}

sub authorize {
    my ($self,$mac) = @_;
    my $logger = Log::Log4perl::get_logger( ref($self) );
    my $result = $self->validate_mac_in_opswat($mac); 
    if( $result == -1){
        $logger->info("OPSWAT Oauth access token is probably not valid anymore.");
        $self->refresh_access_token();
        $result = $self->validate_mac_in_opswat($mac);
    }

    if($result == -1){
        $logger->error("Unable to contact the OPSWAT API to validate if mac $mac is registered.");
        return -1;
    }
    else{
        return $result;
    }   
   
}

=head1 AUTHOR

Inverse inc. <info@inverse.ca>

=head1 COPYRIGHT

Copyright (C) 2005-2014 Inverse inc.

=head1 LICENSE

This program is free software; you can redistribute it and::or
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

1;
