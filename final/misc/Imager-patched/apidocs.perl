#!perl -w
use strict;
use ExtUtils::Manifest 'maniread';

my $outname = shift || '-';

my @funcs = make_func_list();
my %funcs = map { $_ => 1 } @funcs;

# look for files to parse

my $mani = maniread;
my @files = sort grep /\.(c|im|h)$/, keys %$mani;

# scan each file for =item <func>\b
my $func;
my $start;
my %alldocs;
my @funcdocs;
my %from;
my $category;
my %funccats;
my %cats;
my $synopsis = '';
my %funcsyns;
my $order;
my %order;
for my $file (@files) {
  open SRC, "< $file"
    or die "Cannot open $file for documentation: $!\n";
  while (<SRC>) {
    if (/^=item (\w+)\b/ && $funcs{$1}) {
      $func = $1;
      $start = $.;
      @funcdocs = $_;
    }
    elsif ($func && /^=(cut|head)/) {
      if ($funcs{$func}) { # only save the API functions
        $alldocs{$func} = [ @funcdocs ];
        $from{$func} = "File $file";
        if ($category) {
          $funccats{$func} = $category;
          push @{$cats{$category}}, $func;
        }
        if ($synopsis) {
          $funcsyns{$func} = $synopsis;
        }
	defined $order or $order = 50;
	$order{$func} = $order;
      }
      undef $func;
      undef $category;
      undef $order;
      $synopsis = '';
    }
    elsif ($func) {
      if (/^=category (.*)/) {
        $category = $1;
      }
      elsif (/^=synopsis (.*)/) {
	unless (length $synopsis) {
	  push @funcdocs, "\n";
	}
        $synopsis .= "$1\n";
	push @funcdocs, "  $1\n";
      }
      elsif (/^=order (.*)$/) {
	$order = $1;
	$order =~ /^\d+$/
	  or die "=order must specify a number for $func in $file\n";
      }
      else {
        push @funcdocs, $_;
      }
    }
  }
  $func and
    die "Documentation for $func not followed by =cut or =head in $file\n";
  
  close SRC;
}

open OUT, "> $outname"
  or die "Cannot open $outname: $!";

# I keep this file in git and as part of the dist, make sure newlines
# don't mess me up
binmode OUT;

print OUT <<'EOS';
Do not edit this file, it is generated automatically by apidocs.perl
from Imager's source files.

Each function description has a comment listing the source file where
you can find the documentation.

=head1 NAME

Imager::APIRef - Imager's C API - reference.

=head1 SYNOPSIS

  i_color color;
  color.rgba.r = 255; color.rgba.g = 0; color.rgba.b = 255;

EOS

for my $cat (sort { lc $a cmp lc $b } keys %cats) {
  print OUT "\n  # $cat\n";
  my @funcs = @{$cats{$cat}};
  my %orig;
  @orig{@funcs} = 0 .. $#funcs;
  @funcs = sort { $order{$a} <=> $order{$b} || $orig{$a} <=> $orig{$b} } @funcs;
  for my $func (grep $funcsyns{$_}, @funcs) {
    my $syn = $funcsyns{$func};
    $syn =~ s/^/  /gm;
    print OUT $syn;
  }
}

print OUT <<'EOS';

=head1 DESCRIPTION

EOS

my %undoc = %funcs;

for my $cat (sort { lc $a cmp lc $b } keys %cats) {
  print OUT "=head2 $cat\n\n=over\n\n";
  my @ordered_funcs = sort {
    $order{$a} <=> $order{$b}
      || lc $a cmp lc $b
    } @{$cats{$cat}};
  for my $func (@ordered_funcs) {
    print OUT @{$alldocs{$func}}, "\n";
    print OUT "=for comment\nFrom: $from{$func}\n\n";
    delete $undoc{$func};
  }
  print OUT "\n=back\n\n";
}

# see if we have an uncategorised section
if (grep $alldocs{$_}, keys %undoc) {
  print OUT "=head2 Uncategorized functions\n\n=over\n\n";
  #print join(",", grep !exists $order{$_}, @funcs), "\n";
  for my $func (sort { $order{$a} <=> $order{$b} || $a cmp $b }
		grep $undoc{$_} && $alldocs{$_}, @funcs) {
    print OUT @{$alldocs{$func}}, "\n";
    print OUT "=for comment\nFrom: $from{$func}\n\n";
    delete $undoc{$func};
  }
  print OUT "\n\n=back\n\n";
}

if (keys %undoc) {
  print OUT <<'EOS';

=head1 UNDOCUMENTED

The following API functions are undocumented so far, hopefully this
will change:

=over

EOS

  print OUT "=item *\n\nB<$_>\n\n" for sort keys %undoc;

  print OUT "\n\n=back\n\n";
}

print OUT <<'EOS';

=head1 AUTHOR

Tony Cook <tonyc@cpan.org>

=head1 SEE ALSO

Imager, Imager::API, Imager::ExtUtils, Imager::Inline

=cut
EOS

close OUT;


sub make_func_list {
  my @funcs = qw(i_img i_color i_fcolor i_fill_t mm_log mm_log i_img_color_channels i_img_has_alpha i_img_dim i_DF i_DFc i_DFp i_DFcp i_psamp_bits i_gsamp_bits i_psamp i_psampf);
  open FUNCS, "< imexttypes.h"
    or die "Cannot open imexttypes.h: $!\n";
  my $in_struct;
  while (<FUNCS>) {
    /^typedef struct/ && ++$in_struct;
    if ($in_struct && !/SKIP/ && /\(\*f_(i[om]?_\w+)/) {
      my $name = $1;
      $name =~ s/_imp$//;
      push @funcs, $name;
    }
    if (/^\} im_ext_funcs;$/) {
      $in_struct
        or die "Found end of functions structure but not the start";

      close FUNCS;
      return @funcs;
    }
  }
  if ($in_struct) {
    die "Found start of the functions structure but not the end\n";
  }
  else {
    die "Found neither the start nor end of the functions structure\n";
  }
}

=head1 NAME

apidocs.perl - parse Imager's source for POD documenting the C API

=head1 SYNOPSIS

  perl apidocs.perl lib/Imager/APIRef.pod

=head1 DESCRIPTION

Parses Imager's C sources, including .c, .h and .im files searching
for function documentation.

Besides the normal POD markup, the following can be included:

=over

=item =category I<category-name>

The category the function should be in.

=item =synopsis I<sample-code>

Sample code using the function to include in the Imager::APIRef SYNOPSIS

=item =order I<integer>

Allows a function to be listed out of order.  If this isn't specified
it defaults to 50, so a value of 10 will cause the function to be
listed at the beginning of its category, or 90 to list at the end.

Functions with equal order are otherwise ordered by name.

=back

=head1 AUTHOR

Tony Cook <tonyc@cpan.org>

=cut

