#
# Copyright 2016, Deep Information Sciences, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'uri'
require 'chef/provider/lwrp_base'
require_relative './helpers.rb'

class Chef
  class Provider
    class DeepSqlProviderUpstart < DeepSqlProviderBase

      if defined?(provides)
        provides :deepsql_service, :os => 'linux' do
          Chef::Platform::ServiceHelpers.service_resource_providers.include?(:upstart) &&
              !Chef::Platform::ServiceHelpers.service_resource_providers.include?(:redhat)
        end
      end

      action :create do
        Chef::Log.info("Upstart::Create")

        # install system dependencies...

        requirements = %w{
          libaio1
        }

        requirements.each do |package|
          apt_package package do
            action :install
          end
        end

        # install software bundle...

        ruby_block 'set debconf for mysql' do
          block do
            `echo mysql-server mysql-server/root_password password '#{root_password}' | sudo debconf-set-selections`
            `echo mysql-server mysql-server/root_password_again password '#{root_password}' | sudo debconf-set-selections`
            `echo deep-plugin deep-plugin/deep_activation_key string #{new_resource.activation_key} | debconf-set-selections`
            `echo deep-plugin deep-plugin/deep_mysql_root_password password #{root_password} | debconf-set-selections`
          end
          action :create
          not_if { ::File.exists?("/etc/mysql/my.cnf") }
        end

        download_url = new_resource.install_bundle_url
        if download_url.nil?
          download_url = "https://deepsql.s3.amazonaws.com/apt/#{node['platform']}/trusty/mysql-#{new_resource.version}/deepsql_3.3.1_amd64.deb-bundle.tar"
        end

        tmp = '/tmp'
        path = "#{tmp}/#{URI(download_url).path.split('/').last}"
        Chef::Log.info(download_url)
        Chef::Log.info(path)

        remote_file path do
          source download_url
          action :create_if_missing
        end

        execute "tar xf #{path}" do
          cwd tmp
        end

        packages = %w{
          mysql-common
          libmysqlclient18
          libmysqlclient-dev
          mysql-community-client
          mysql-client
          mysql-community-server
          mysql-server
          deep-mysql-community-plugin
        }

        packages.each do |package|
          package package do
            action :install
            provider Chef::Provider::Package::Dpkg
            source "/tmp/bundle/#{package}.deb"
          end
        end

      end

      action :delete do
      end

      action :start do
      end

      action :stop do
      end

      private

      def something
      end

    end
  end
end
