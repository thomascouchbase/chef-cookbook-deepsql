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
        provides :deepsql_service, os: 'linux' do
          Chef::Platform::ServiceHelpers.service_resource_providers.include?(:upstart) &&
              !Chef::Platform::ServiceHelpers.service_resource_providers.include?(:redhat)
        end
      end

      def stop_system_service
        service "#{new_resource.name} :create #{system_service_name}" do
          service_name system_service_name
          provider Chef::Provider::Service::Init
          supports status: true
          action [:stop, :disable]
        end
      end

      def configure_system_security
        package "#{new_resource.name} :create apparmor" do
          package_name 'apparmor'
          action :install
        end

        directory "#{new_resource.name} :create /etc/apparmor.d/local/mysql" do
          path '/etc/apparmor.d/local/mysql'
          owner 'root'
          group 'root'
          mode '0755'
          recursive true
          action :create
        end

        template "#{new_resource.name} :create /etc/apparmor.d/local/usr.sbin.mysqld" do
          path '/etc/apparmor.d/local/usr.sbin.mysqld'
          cookbook 'deepsql'
          source 'apparmor/usr.sbin.mysqld-local.erb'
          owner 'root'
          group 'root'
          mode '0644'
          action :create
          notifies :restart, "service[#{new_resource.name} :create apparmor]", :immediately
        end

        template "#{new_resource.name} :create /etc/apparmor.d/usr.sbin.mysqld" do
          path '/etc/apparmor.d/usr.sbin.mysqld'
          cookbook 'deepsql'
          source 'apparmor/usr.sbin.mysqld.erb'
          owner 'root'
          group 'root'
          mode '0644'
          action :create
          notifies :restart, "service[#{new_resource.name} :create apparmor]", :immediately
        end

        template "#{new_resource.name} :create /etc/apparmor.d/local/mysql/#{new_resource.instance}" do
          path "/etc/apparmor.d/local/mysql/#{new_resource.instance}"
          cookbook 'deepsql'
          source 'apparmor/usr.sbin.mysqld-instance.erb'
          owner 'root'
          group 'root'
          mode '0644'
          variables(data_dir: parsed_data_dir,
                    deepsql_name: deepsql_name,
                    log_dir: log_dir,
                    run_dir: run_dir,
                    pid_file: pid_file,
                    socket_file: socket_file)
          action :create
          notifies :restart, "service[#{new_resource.name} :create apparmor]", :immediately
        end

        service "#{new_resource.name} :create apparmor" do
          service_name 'apparmor'
          action :nothing
        end
      end

      def install_software
        Chef::Log.info('[deepSQL Cookbook] Upstart::Create')

        # install system dependencies...

        requirements = %w(
          libaio1
        )

        requirements << 'libnuma1' if precise?

        requirements.each do |package|
          apt_package package do
            action :install
          end
        end

        # install software bundle...

        ruby_block 'set debconf for mysql' do
          block do
            `echo deepsql-server deepsql-server/root-pass password #{root_password} | debconf-set-selections`
            `echo deepsql-server deepsql-server/re-root-pass password #{root_password} | debconf-set-selections`
            `echo deep-plugin deep-plugin/deep_activation_key string #{new_resource.activation_key} | debconf-set-selections`
            `echo deep-plugin deep-plugin/deep_mysql_root_password password #{root_password} | debconf-set-selections`
          end
          action :create
          not_if { ::File.exist?('/etc/mysql/my.cnf') }
        end

        # permit customers to point their chef recipes at internal package
        # repositories on secured networks behind firewalls...
        download_url = new_resource.install_bundle_url
        if download_url.nil?
          download_url = "#{bundle_directory_url}/deepsql_#{new_resource.version}_amd64.deb-bundle.tar"
        end
        bundle = URI(download_url).path.split('/').last.to_s

        # eng: if we use deb bundles, nothing below should have to
        # change; reach out if you have questions. - bob

        file_cache_path = Chef::Config[:file_cache_path].to_s
        cached_bundle = "#{file_cache_path}/#{bundle}"
        remote_file cached_bundle do
          source download_url
          action :create_if_missing
        end

        execute "tar xf #{cached_bundle}" do
          cwd file_cache_path.to_s
        end

        prefixes = %w(
          deepsql-common
          deepsql-client
          libdeepsqlclient18
          deepsql-server
          deepsql-plugin
        )

        prefixes.each do |prefix|
          package prefix.to_s do
            action :install
            provider lazy {
              platform_package_provider
            }
            source lazy {
              first_match("#{file_cache_path}/#{prefix}*.#{platform_package_type}")
            }
          end
        end
      end

      action :delete do
      end

      action :start do
        template "#{new_resource.name} :start /usr/sbin/#{deepsql_name}-wait-ready" do
          path "/usr/sbin/#{deepsql_name}-wait-ready"
          source 'upstart/mysqld-wait-ready.erb'
          owner 'root'
          group 'root'
          mode '0755'
          variables(defaults_file: defaults_file)
          cookbook 'deepsql'
          action :create
        end

        template "#{new_resource.name} :start /etc/init/#{deepsql_name}.conf" do
          path "/etc/init/#{deepsql_name}.conf"
          source 'upstart/mysqld.erb'
          owner 'root'
          group 'root'
          mode '0644'
          variables(defaults_file: defaults_file,
                    deepsql_name: deepsql_name,
                    pid_file: pid_file,
                    run_group: new_resource.run_group,
                    run_user: new_resource.run_user,
                    run_dir: run_dir,
                    socket_dir: socket_dir,
                    socket_file: socket_file)
          cookbook 'deepsql'
          action :create
        end

        service "#{new_resource.name} :start #{deepsql_name}" do
          service_name deepsql_name
          provider Chef::Provider::Service::Upstart
          supports status: true
          action [:start]
        end
      end

      action :stop do
      end

      private

      def something
      end
    end
  end
end
