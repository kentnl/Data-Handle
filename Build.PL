
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Data::Dumper" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "IO::Handle" => 0,
    "Module::Build" => "0.4002",
    "Test::Fatal" => 0,
    "Test::More" => "0.98"
  },
  "configure_requires" => {
    "Module::Build" => "0.4002"
  },
  "dist_abstract" => "A Very simple interface to the __DATA__  file handle.",
  "dist_author" => [
    "Kent Fredric <kentnl\@cpan.org>"
  ],
  "dist_name" => "Data-Handle",
  "dist_version" => "0.02001002",
  "license" => "perl",
  "module_name" => "Data::Handle",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => "1.22",
    "IO::File" => 0,
    "Package::Stash" => 0,
    "Scalar::Util" => 0,
    "Symbol" => 0,
    "Term::ANSIColor" => 0,
    "Try::Tiny" => 0,
    "overload" => 0,
    "parent" => 0,
    "perl" => "5.008",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
