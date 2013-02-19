package Easy::Option;

use strict;
use warnings;
use Carp;
use Data::Dumper;
use base 'Exporter';

our @EXPORT = qw/getoptions/;
our $VERSION = '0.01';

BEGIN{
    @__PACKAGE__::ARGALL = @ARGV;
}

sub getoptions {
    my %option = _hashnize(@_);
    my %seems_opt = _get_seems_opt(@__PACKAGE__::ARGALL);
    my %fix_option = _fix_option(\%option,%seems_opt);
    return %fix_option;
}

# i int
# s str
# b bool
sub _hashnize {
    my @arg = @_;
    my %opt;
    for (@arg){
        my ($name,$type) = split/:/;
        $type = "b" if !$type;          #default type bool
        length $type >= 2 and croak "More than two types of option specified to one variable [$name:$type]";
        for (split//,$type){
            if (/[^bis]/){
                croak "Unknown option type [$_]"; 
            }
            my $short = substr($name,0,1);
            croak "First letter of option must be uniq" if $opt{$short};
            $opt{$short}{type} = $_;
            $opt{$short}{long} = $name;
        }
    }
    return %opt;
}

sub _get_seems_opt {
    my @argvall = @_;
    my %seems_opt;
    my $last_opt;           # flag
    my $is_long;
    while (local $_ = shift @argvall){
        if (s/^--//){
            my ($key,$val) = split/=/;
            $seems_opt{long}{$key}  = $val || undef;
        }
        elsif (s/^-//){
            do{$seems_opt{short}{$last_opt} = "-"} and next if /^-$/;
            $seems_opt{short}{$_} = undef;
            $last_opt = $_;
        }
        else{
            $last_opt and $seems_opt{short}{$last_opt} ||= $_;
        }
    }
    return %seems_opt;
}

sub _fix_option {
    my %option = %{+shift};
    my %seems_opt = @_;
    my %option_fixed;
    for my $optarg (keys %{$seems_opt{long}}){
        my $short = substr($optarg,0,1);
        die "Unknown option [--$optarg]\n" if $option{$short}{long} ne $optarg;
        if ($option{$short}{type} eq "s" && !$seems_opt{long}{$optarg}){
            die "Option [--$optarg] require argument\n";
        }
        elsif ($option{$short}{type} eq "i" && ( !$seems_opt{long}{$optarg} || $seems_opt{long}{$optarg} =~ /\D/ )){
            die "Option [--$optarg] require numeric argument\n";
        }
        $option_fixed{$optarg} = $seems_opt{long}{$optarg} || "-";      # bool value "-"
    }
    for my $optarg (keys %{$seems_opt{short}}){
        my $optarg_origin = $optarg;
        while ($optarg =~ s/^(\w)//g){
            my $s_opt = $1;
            die "Unknown option [-$s_opt]\n" if !exists $option{$s_opt};
            if ($option{$s_opt}{type} eq "b"){
                $option_fixed{$option{$s_opt}{long}} = "-";             # bool value "-"
            }
            elsif ($option{$s_opt}{type} eq "s"){
                my $arg = $optarg || $seems_opt{short}{$optarg_origin};
                die "Option [-$s_opt] requires argument\n" if !$arg;
                $option_fixed{$option{$s_opt}{long}} = $arg;
                last;
            }
            elsif ($option{$s_opt}{type} eq "i"){
                my $arg = $optarg || $seems_opt{short}{$optarg_origin};
                die "Option [-$s_opt] requires numeric argument\n" if $arg !~ /^\d+$/;
                $option_fixed{$option{$s_opt}{long}} = $arg;
                last;
            }
        }
    }
    return %option_fixed;
}

1;
__END__

=head1 NAME

Easy::Option - Command line option tool

=head1 SYNOPSIS

  use Easy::Option;
  
  my %opt = getoptions(qw/file:s date:i verbose:b/);
  my $filename = $opt{file} || "default_file";
  my $date     = $opt{date} || $now;
  my $verbose  = $opt{verbose} ? 1 : 0;

=head2 FUNCTION

  getoptions()      Set option name and type like "date:i" then call your script 
                    with option -d20130220 or --date=20130220.It returns option 
                    value as hash.
                    my %opt = getoptions(qw/name1:type name2:type/);

                    Allow type ...
                    s       string  ... accept any character
                    i       integer ... only integer
                    b       bool    ... flag
                    
                    And first letter of name must be uniq.

=head1 AUTHOR

IWASAKI Tooru


=cut
