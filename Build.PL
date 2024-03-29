#!/usr/bin/perl
use strict;
use warnings;

use Module::Build;

Module::Build->new
    ( module_name => 'HTTP::Server::Simple::Static',
      dist_author => 'Stephen Quinney <sjq-perl@jadevine.org.uk>',
      license     => 'perl',
      create_makefile_pl => 'traditional',
      requires    => {
	  'CGI'                   => '3.46',
          'Exporter'              => 0,
          'File::LibMagic'        => 0,
          'File::Spec::Functions' => 0,
          'HTTP::Date'            => 0,
          'HTTP::Server::Simple'  => 0.01 ,
          'IO::File'              => 0,
          'URI::Escape'           => 0,
      },
    )->create_build_script;
