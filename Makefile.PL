use inc::Module::Install 0.67;

name 'Catalyst-Plugin-Session-State-Cookie';
all_from 'lib/Catalyst/Plugin/Session/State/Cookie.pm';

requires 'Catalyst'                  => '5.7010';
requires 'Catalyst::Plugin::Session' => '0.19';
requires 'Test::MockObject'          => '1.01';

auto_install;
WriteAll;
