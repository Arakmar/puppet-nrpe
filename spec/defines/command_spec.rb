# frozen_string_literal: true

require 'spec_helper'

describe 'nrpe::command' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let :facts do
        facts
      end

      let(:title) { 'check_users' }
      let(:params) do
        {
          command: 'check_users -w 5 -c 10',
          ensure: 'present',
        }
      end

      it { is_expected.to compile.with_all_deps }

      case facts[:os]['family']
      when 'Debian'
        it {
          is_expected.to contain_file('/etc/nagios/nrpe.d/check_users.cfg').with(
            'mode' => '0644',
          ).that_requires(['Package[nagios-nrpe-server]'])
        }
      when 'Gentoo'
        it {
          is_expected.to contain_file('/etc/nagios/nrpe.d/check_users.cfg').with(
            'mode' => '0644',
          ).that_requires(['Package[net-analyzer/nrpe]'])
        }
      when 'FreeBSD'
        it {
          is_expected.to contain_file('/usr/local/etc/nrpe.d/check_users.cfg').with(
            'mode' => '0644',
          ).that_requires(['Package[nrpe]'])
        }
      when 'Archlinux'
        it {
          is_expected.to contain_file('/etc/nrpe/nrpe.d/check_users.cfg').with(
            'mode' => '0644',
          ).that_requires(['Package[nrpe]'])
        }
      else
        it {
          is_expected.to contain_file('/etc/nrpe.d/check_users.cfg').with(
            'mode' => '0644',
          ).that_requires(['Package[nrpe]'])
        }
      end

      context 'with a custom include_dir' do
        let(:pre_condition) { "class { 'nrpe': include_dir => '/etc/nrpe.d' }" }

        it {
          is_expected.to contain_file('/etc/nrpe.d/check_users.cfg').with(
            'owner' => 'root',
            'group' => %w[FreeBSD OpenBSD].include?(facts[:os]['family']) ? 'wheel' : 'root',
            'mode'  => '0644',
          )
        }

        context 'when the command files are restricted to the nrpe group' do
          let(:pre_condition) do
            <<~PUPPET
              class { 'nrpe':
                include_dir               => '/etc/nrpe.d',
                command_file_group        => 'nrpe-group',
                command_file_default_mode => '0640',
              }
            PUPPET
          end

          it {
            is_expected.to contain_file('/etc/nrpe.d/check_users.cfg').with(
              'owner' => 'root',
              'group' => 'nrpe-group',
              'mode'  => '0640',
            )
          }
        end
      end
    end
  end
end
