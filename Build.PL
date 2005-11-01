use strict;
use Module::Build;

my $build = Module::Build->new(
    create_makefile_pl => 'traditional',
    license            => 'perl',
    module_name        => 'Catalyst::Plugin::Session::State::Cookie',
    requires           => {
        'Catalyst::Plugin::Session' => '0.01',
        'Test::MockObject'          => '1.01',
    },
    create_readme => 1,
    sign          => 1,
);
$build->create_build_script;

