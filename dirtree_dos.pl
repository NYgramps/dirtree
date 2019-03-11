# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Name:        dirtree_dos.pl
# Purpose:     display collapsible directory tree of drive usage
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use strict;
use Carp;
use IO::File;
use DirHandle;
use File::Basename qw(fileparse);
use Cwd qw(abs_path);
use Pod::Usage;
use v5.10;

use constant {
              SIZE => 0,
#             SIZE => 100000,      # 100 KB
#             SIZE => 1000000,     # 1 MB
              DAY  => 60*60*24,
              AGE  => 0,
#             AGE  => 7*DAY,       # 1 week
#             AGE  => 91*DAY,      # 1/4 year
#             AGE  => 182*DAY,     # 1/2 year
             };

exit(main());

        # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub main
  {
  my %usage_opt = (-msg => "\nenter 'perldoc $0' to see complete documentation\n",
                   -exitval => 0,
                   -verbose => 99,
                   -sections => [qw(USAGE DESCRIPTION)]);

  my $root = $ARGV[0];
  if (-d $root)
    {
    $root =~ s/\/$//;     # remove final '/', if present
    }
  else
    {
    say("FATAL: $root is not a directory");
    pod2usage(\%usage_opt);
    }

  $root = abs_path($root);
  my $filename = fileparse($root);
  $filename =~ s/\s/_/g;
  $filename .= '.html';

  my $filter = sub
    { 
    my $path = shift;
    my $size = (-s $path);
    my $age = time() - (stat($path))[9];
    return( ($age > AGE and $size > SIZE) ? $size : 0 );
    };

  my $tree = {};
  my $iter = walkTree($root, $filter);
  while (my $ref = nextval($iter))
    {
    my ($path, $arr, $size) = @{$ref};
    $tree->{$path} = {subdir => $arr, size => $size, leaf => 0, done => 0};
    unless (scalar(@{$arr}))
      {
      $tree->{$path}{leaf} = 1;
      $tree->{$path}{done} = 1;
      }
    }

# ***
#  At this point, each path size is equal to the sum of the sizes of the
#  contained files; contained subdirectories have not yet been sized.
#  However, leaf sizes are already correct because leaves do not contain
#  subdirectories.  Any folder containing a 'deepest' leaf can be sized
#  correctly by adding in all leaf sizes because any other leaves must also 
#  be 'deepest', by definition of 'deepest', and the folder is 'done'.
#  Each pass over the tree will increase the number of 'done' subdirectories,
#  and the updating will be complete when all are marked 'done'.
# ***
 
  my $again = 1;
  while ($again)
    {
    $again = 0;
OUTER:
    foreach my $path (keys %{$tree})
      {
      next if (($tree->{$path}{done}));
      unless (defined($tree->{$path}{subdir}))
        {
        $tree->{$path}{done} = 1;
        next;
        }
      $again = 1;
      my @subdir = @{$tree->{$path}{subdir}};
      my $sum = 0;
      foreach my $sub (@subdir)
        {
        next OUTER unless ($tree->{$sub}{done});
        $sum += $tree->{$sub}{size};
        }
      $tree->{$path}{size} += $sum;
      $tree->{$path}{done} = 1;
      }
    }    # end of section for updating folder sizes

  writeHTML($tree, $root, $filename);

  return(0);
  }

        # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub walkTree
  {
  my $root = shift;
  my $filter = shift;

  my @queue = ($root);
  my %xref;

  return sub              # iterator via closure
    {
    while (@queue)
      {
      my $dir = shift @queue;
      if (-l $dir)
        {
        my $targ = readlink($dir);
        say "$dir -> $targ";
        }
      my $qq = "\"$dir\"";
      my $attr = `attrib $qq`;
      my @arr = split(/\\/, $attr);
      my $str = substr($arr[0], 0, -2);
      if ($str =~ /[SH]/)
        {
        say "$dir has HIDDEN and/or SYSTEM attribute = $attr - skipping";
        next;
        }
      my ($dh, @subdir);
      unless ($dh = DirHandle->new($dir))
        {
        say "cannot open $dir - skipping";
        next;
        }

      my $size = 0;
      foreach my $file ($dh->read())
        {
        next if ($file =~ /^\.+$/);
        next if (-l $dir);
        next if (-l $file);
        my $path = "$dir/$file";
        if (-d $path)
          {
          unless (DirHandle->new($path))
            {
            say "cannot open directory $path";
            next;
            }
          $qq = "\"$path\"";
          $attr = `attrib $qq`;
          @arr = split(/\\/, $attr);
          $str = substr($arr[0], 0, -2);
          if ($str =~ /[SH]/)
            {
            say "$path has HIDDEN and/or SYSTEM attribute = $attr - skipping";
            next;
            }
          push(@subdir, $path);
          }
        else
          {
          $size += $filter->($path);
          }
        }

      push(@queue, @subdir) if (scalar(@subdir));
      return([$dir, \@subdir, $size]);
      }
    return undef;
    };
  }

        # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub nextval
  {
  my $iter = shift;
  return($iter->());
  }

        # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub writeHTML
  {
  my ($tree, $root, $filename) = @_;

  my $nleaf = leafcount($tree);

  croak("cannot write to $filename\n") unless my $OUT = IO::File->new($filename, '>');

  my $head =
q(<!DOCTYPE html>
<html lang="en-US">
<head>
  <title>Directory Tree Usage</title>
  <link rel='stylesheet' href='css/dirtree.css' type='text/css'>
</head>
<body>
<!--            * * * *         OVERVIEW         * * * *
*
*        The directory tree in HTML format is represented as a set of
*        nested unordered lists.  The data associated with any <li> tag
*        is contained in an HTML table having 1 row and 3 columns:
*        an image, directory name, and directory size equal to the
*        sum of the sizes of all its contained files, plus the sum of
*        the sizes of all its subdirectories.
*        Each <ul> tag is associated with a directory which
*        contains subdirectories, and its first child <li> tag displays
*        the data for that directory; succeeding child <li> tags
*        correspond to 'leaf' subdirectories, that is, subdirectories
*        not having subdirecories of their own, followed by subdirectories
*        of the original parent directory which do have subdirectories.
*
-->
  <div id='box'>
    <button type='button' class='buttons' id='btnOpen'>OPEN ALL</button>
    <button type='button' class='buttons' id='btnClose'>CLOSE ALL</button>
    <button type='button' class='buttons' id='btnAbout'>ABOUT</button>
  </div>);

  $OUT->say($head);

  recur($root, $tree, $nleaf, $OUT);

  my $tail = q(
<script src='js/dirtree.js' type='text/javascript'></script>
</body>
</html>
);

  $OUT->say($tail);
  $OUT->close();
  return;
  }

        # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub recur
  {
  my ($path, $tree, $nleaf, $OUT) = @_;

  state $root = $path;
  state $count = 0;

  my ($attr, @subdir, $sub, $dir);
  my ($name) = fileparse($path);
  my $size = $tree->{$path}{size} || 0;
  my $leaf = $tree->{$path}{leaf} || 0;

  if ($leaf == 1)        # trivial case where the root is a leaf
    {
    $attr = {id => q(), tbl => q(class='adj'), td => q('leaf')};
    $OUT->print(getLI($name, $size, $attr));
    }
  else
    {
    $OUT->say();
    if ($path eq $root)
      {
      $OUT->print('  <ul>');
      $attr = {id => q(id='root'), tbl => q(), td => q('folder')};
      }
    else
      {
      $OUT->print('  <li><ul>');
      $attr = {id => q() , tbl => q(), td => q('folder')};
      }
    $OUT->print(getLI($name, $size, $attr));

    @subdir = leafsort($tree, $path);

    foreach $sub (@subdir)
      {
      ($name, $dir) = fileparse($sub);
      $size = $tree->{$sub}{size};
      $leaf = $tree->{$sub}{leaf};
      if ($leaf == 1)
        {
        $attr = {id => q(), tbl => q(class='adj'), td => q('leaf')};
        $OUT->print(getLI($name, $size, $attr));
        $count++;
        }
      else
        {
        recur($sub, $tree, $nleaf, $OUT);
        }
      }

    ($count < $nleaf) ? $OUT->say("  </ul></li>") : $OUT->say("  </ul>");
    }

  return;
  }

        # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub getLI
  {
  my ($dir, $size, $attr) = @_;

  my $li = qq(
    <li $attr->{id}><table $attr->{tbl}><tr>
       <td class=$attr->{td}></td>
       <td>$dir</td>
       <td>$size</td></tr></table>
    </li>
);

  return($li);
  }

        # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub leafsort
  {
  my ($tree, $path) = @_;

  my (@arr, $sub);
  foreach $sub (@{$tree->{$path}{subdir}})
    {
    push(@arr, ($sub)) if ($tree->{$sub}{leaf});
    }
  foreach $sub (@{$tree->{$path}{subdir}})
    {
    push(@arr, ($sub)) unless ($tree->{$sub}{leaf});
    }
  return(@arr);
  }

        # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub leafcount
  {
  my $tree = shift;

  my $nleaf = 0;
  foreach my $path (keys %{$tree})
    {
    $nleaf++ if ($tree->{$path}{leaf});
    }
  return($nleaf);
  }

__END__

=pod

=head1 USAGE

    dirtree_dos.pl <path of root of desired subtree>

=head1 DESCRIPTION

The output of this program is an HTML file which displays the hard disk
usage of all the directories of interest, as a collapsible tree;
this display is supported by most modern browsers.  A filter is available
to constrain files by SIZE and AGE.

=head1 CLOSURES

=head2 walkTree

Data is stored in a hash for every path in the directory tree as it is
navigated by 'walkTree'.

=head1 SUBROUTINES

=head2 filter

The anonymous subroutine, 'filter', determines the admissibility of files
according to the values assigned to the constants SIZE and AGE, both having
a default value of 0. (Although it is considered bad programming practice to
edit source code to set a value, in this instance it really is much simpler to
adjust comments, i.e. pound signs, appropriately...mea culpa).

=head2 writeHTML

The 'writeHTML' function writes the output file in html format for
display as a collapsible directory tree in most modern browsers.

=head2 recur

This routine writes out HTML code for each path in the tree recursively
as an item in a nested set of unordered lists.

=head2 leafsort

For a given directory, 'leafsort' returns an array with all leaves listed
before all subdirectories containing additional subdirectories of their
own.

=head2 leafcount

A count of the total number of leaves in the tree is returned by 'leafcount'.


=cut
