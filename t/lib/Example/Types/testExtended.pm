package Example::Types::testExtended;
use strict;
use warnings;


__PACKAGE__->_set_element_form_qualified(1);

sub get_xmlns { 'urn:HelloWorld' };

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}

use Class::Std::Fast::Storable constructor => 'none';
use base qw(SOAP::WSDL::XSD::Typelib::ComplexType);

Class::Std::initialize();

{ # BLOCK to scope variables

my %extend_of :ATTR(:get<extend>);

__PACKAGE__->_factory(
    [ qw(        extend

    ) ],
    {
        'extend' => \%extend_of,
    },
    {
        'extend' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
    },
    {

        'extend' => 'extend',
    }
);

} # end BLOCK







1;


=pod

=head1 NAME

Example::Types::testExtended

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
testExtended from the namespace urn:HelloWorld.






=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * extend




=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # Example::Types::testExtended
   extend =>  $some_value, # string
 },




=head1 AUTHOR

Generated by SOAP::WSDL

=cut
