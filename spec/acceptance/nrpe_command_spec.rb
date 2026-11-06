# frozen_string_literal: true

require 'spec_helper_acceptance'

case fact('osfamily')
when 'Debian'
  nrpe_plugin_package = 'nagios-nrpe-plugin'
  nrpe_plugindir      = '/usr/lib/nagios/plugins'
  nrpe_includedir     = '/etc/nagios/nrpe.d'
  nrpe_group          = 'nagios'
when 'FreeBSD'
  nrpe_plugin_package = 'nagios-plugins'
  nrpe_plugindir      = '/usr/local/libexec/nagios'
  nrpe_includedir     = '/usr/local/etc/nrpe.d'
  nrpe_group          = 'nagios'
when 'Archlinux'
  nrpe_plugin_package = 'nrpe'
  nrpe_plugindir      = '/usr/lib/monitoring-plugins'
  nrpe_includedir     = '/etc/nrpe/nrpe.d'
  nrpe_group          = 'nrpe'
else
  nrpe_plugin_package = 'nagios-plugins-nrpe'
  nrpe_plugindir      = '/usr/lib64/nagios/plugins'
  nrpe_includedir     = '/etc/nrpe.d'
  nrpe_group          = 'nrpe'
end

describe 'nrpe::command class' do
  describe 'Scenario: default_commands' do
    include_examples 'the example', 'default_commands.pp'
    describe 'the NRPE includedir' do
      describe file(nrpe_includedir) do
        it { is_expected.to be_a_directory }
      end

      describe command("ls #{nrpe_includedir}/*.cfg | wc -l") do
        its(:stdout) { is_expected.to match('5') }
      end
    end
  end

  describe 'Scenario: purge_commands' do
    include_examples 'the example', 'purge_commands.pp'

    describe command("ls #{nrpe_includedir}/*.cfg | wc -l") do
      its(:stdout) { is_expected.to match('1') }
    end
  end

  describe 'Scenario: check_dummy' do
    before do
      apply_manifest("package { '#{nrpe_plugin_package}': ensure => present }", catch_failures: true)
    end

    include_examples 'the example', 'check_dummy.pp'

    describe command("#{nrpe_plugindir}/check_nrpe -H 127.0.0.1 -c check_dummy") do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match('OK') }
    end
  end

  describe 'Scenario: command files readable by the nrpe group only' do
    let(:pp) do
      <<~PUPPET
        class { 'nrpe':
          command_file_group        => '#{nrpe_group}',
          command_file_default_mode => '0640',
        }

        nrpe::command { 'check_dummy':
          command => 'check_dummy 0',
        }
      PUPPET
    end

    it_behaves_like 'an idempotent resource'

    describe file("#{nrpe_includedir}/check_dummy.cfg") do
      it { is_expected.to be_mode 640 }
      it { is_expected.to be_owned_by 'root' }
      it { is_expected.to be_grouped_into nrpe_group }
    end

    describe command("#{nrpe_plugindir}/check_nrpe -H 127.0.0.1 -c check_dummy") do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match('OK') }
    end
  end
end
