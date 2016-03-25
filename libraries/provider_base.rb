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

require 'chef/provider/lwrp_base'
require_relative './helpers.rb'

class Chef
  class Provider
    class DeepSqlProviderBase < Chef::Provider::LWRPBase
      use_inline_resources if defined?(use_inline_resources)

      include DeepSql::Helper

      def whyrun_supported?
        true
      end

      action :create do
        Chef::Log.info('[deepSQL Cookbook] Base::Create')

        install_software

        stop_system_service

        unless ::File.exist?('/.dockerenv') || ::File.exist?('/.dockerinit')
          configure_system_security
        end

        create_group_and_user

        delete_existing_my_cnf

        create_support_directories

        create_configuration_file

        initialize_database
      end

      def delete_existing_my_cnf
        # Turns out that mysqld is hard coded to try and read
        # /etc/mysql/my.cnf, and its presence causes problems when
        # setting up multiple services.
        file "#{new_resource.name} :create /etc/mysql/my.cnf" do
          path "/etc/mysql/my.cnf"
          action :delete
        end
      end

      def initialize_database
        bash "#{new_resource.name} :create initial records" do
          code init_records_script
          returns [0, 1, 2]
          not_if { ::File.exist?("#{parsed_data_dir}/mysql/user.frm") }
          action :run
        end
      end

      def create_configuration_file
        template "#{new_resource.name} :create #{etc_dir}/my.cnf" do
          path "#{etc_dir}/my.cnf"
          source 'my.cnf.erb'
          cookbook 'deepsql'
          owner new_resource.run_user
          group new_resource.run_group
          mode '0644'
          variables(config: new_resource,
                    error_log: error_log,
                    include_dir: include_dir,
                    lc_messages_dir: lc_messages_dir,
                    pid_file: pid_file,
                    socket_file: socket_file,
                    tmp_dir: tmp_dir,
                    data_dir: parsed_data_dir)
          action :create
        end

        template "#{new_resource.name} :create #{etc_dir}/conf.d/deep.cnf" do
          path "#{etc_dir}/conf.d/deep.cnf"
          source 'deep.cnf.erb'
          cookbook 'deepsql'
          owner new_resource.run_user
          group new_resource.run_group
          mode '0644'
          action :create
        end
      end

      action :delete do
      end

      private

      def create_group_and_user
        # System users
        group "#{new_resource.name} :create mysql" do
          group_name 'mysql'
          action :create
        end

        user "#{new_resource.name} :create mysql" do
          username 'mysql'
          gid 'mysql'
          action :create
        end
      end

      def create_support_directories
        # Support directories
        directory "#{new_resource.name} :create #{etc_dir}" do
          path etc_dir
          owner new_resource.run_user
          group new_resource.run_group
          mode '0755'
          recursive true
          action :create
        end

        directory "#{new_resource.name} :create #{run_dir}" do
          path run_dir
          owner new_resource.run_user
          group new_resource.run_group
          mode '0755'
          recursive true
          action :create
        end

        directory "#{new_resource.name} :create #{include_dir}" do
          path include_dir
          owner new_resource.run_user
          group new_resource.run_group
          mode '0755'
          recursive true
          action :create
        end

        directory "#{new_resource.name} :create #{log_dir}" do
          path log_dir
          owner new_resource.run_user
          group new_resource.run_group
          mode '0750'
          recursive true
          action :create
        end

        directory "#{new_resource.name} :create #{parsed_data_dir}" do
          path parsed_data_dir
          owner new_resource.run_user
          group new_resource.run_group
          mode '0750'
          recursive true
          action :create
        end
      end
    end
  end
end
