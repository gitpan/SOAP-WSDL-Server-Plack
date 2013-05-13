package SOAP::WSDL::Server::Plack;
use Moose;
use MooseX::FollowPBP;

# ABSTRACT: Plack application for SOAP::WSDL Server modules

use Carp;
use namespace::autoclean;
use Try::Tiny;
use Plack::Request;
use Plack::Util;
use HTTP::Request;
use HTTP::Headers;


has 'dispatch_to' => (
	is => 'rw',
	isa => 'Str',
	required => 1,
	documentation => 'Perl module with the SOAP method implementation',
);


has 'soap_service' => (
	is => 'rw',
	isa => 'Str',
	required => 1,
	documentation => 'Perl module with the SOAP::WSDL server implementation',
);


has 'transport_class' => (
	is => 'rw',
	isa => 'Str',
	documentation => 'Transport class',
);


sub psgi_app {
	my ($self) = @_;

	return sub {
		my $env = shift;
		my $req = Plack::Request->new($env);
		my $res;
		my $logger = $req->logger();
		$logger = sub { } unless defined $logger;

		my $dispatch_to = $self->get_dispatch_to();
		if (!$dispatch_to) {
			$logger->({
				level => 'error',
				message => "No 'dispatch_to' variable set in PlackHandler",
			});
			$res = $req->new_response(500);
			return $res->finalize();
		}
		Plack::Util::load_class($dispatch_to);

		my $soap_service_package = $self->get_soap_service();
		if (!$soap_service_package) {
			$logger->({
				level => 'error',
				message => "No 'soap_service' variable set in PlackHandler",
			});
			$res = $req->new_response(500);
			return $res->finalize();
		}
		Plack::Util::load_class($soap_service_package);

		my $transport_class = $self->get_transport_class();
		unless ($transport_class) {
			# if no transport class was specified, use this package's
			# Transport class with its handle() method
			$transport_class = __PACKAGE__ . '::Transport';
		}
		Plack::Util::load_class($transport_class);

		my $server = $soap_service_package->new({
			dispatch_to => $dispatch_to,         # methods
			transport_class => $transport_class, # handle() class
		});

		my $response_msg = $server->handle($req);
		if (defined $response_msg && $response_msg =~ /^\d{3}$/) {
			$logger->({
				level => 'error',
				message => "Dispatcher returned HTTP $response_msg",
			});
			$res = $req->new_response($response_msg);
			return $res->finalize();
		}

		if ($response_msg) {
			$res = $req->new_response(200);
			$res->content_type('text/xml; charset="utf-8"');
			$res->body($response_msg);
			return $res->finalize();
		}
		else {
			$logger->({
				level => 'error',
				message => "No response returned from dispatcher",
			});
			$res = $req->new_response(500);
			return $res->finalize();
		}
	}
}

__PACKAGE__->meta->make_immutable();



__END__
=pod

=head1 NAME

SOAP::WSDL::Server::Plack - Plack application for SOAP::WSDL Server modules

=head1 VERSION

version 0.005

=head1 SYNOPSIS

	use Plack::Runner;
	use SOAP::WSDL::Server::Plack;

	my $app = SOAP::WSDL::Server::Plack({
		dispatch_to => 'My::SOAPMethodImplementation',
		soap_service => 'My::Server::SimpleServer::SimpleServerSoap',
	})->psgi_app();

	my $runner = Plack::Runner->new;
	$runner->parse_options(@ARGV);
	$runner->run($app);

=head1 DESCRIPTION

Plack application wrapper for SOAP::WSDL module providing the
L<SOAP::WSDL::Server> interface.

This is mostly based on L<SOAP::WSDL::Server::Mod_Perl2> implementation
and adapted for Plack.

=head1 ATTRIBUTES

=over

=item dispatch_to

Perl module with the SOAP method implementation

Method dispatcher class, that's where your methods are
actually implemented.

=item soap_service

Perl module with the SOAP::WSDL server implemenation

SOAP server class, that's where the interface is defined.
Usually this is the SOAP::WSDL Server interface as generated by
C<wsdl2perl.pl>.

=item transport_class I<optional>

Transport class

If not specified it defaults to L<SOAP::WSDL::Server::Plack::Transport>

=back

=head1 METHODS

=head2 psgi_app

Return a PSGI application suitable for your PSGI ready webserver.

=head1 SEE ALSO

L<SOAP::WSDL::Server::Plack::Transport> - transport class

=head1 COPYRIGHT AND LICENCE

Copyright 2013 by futureLAB AG under the perl

This module is free software and is published under the same terms as Perl itself.

=head1 AUTHOR

Andreas Stricker <andy@knitter.ch>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by futureLAB AG, info@futurelab.ch.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

