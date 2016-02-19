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

require 'chef/resource/lwrp_base'

class Chef
  class Resource
    class DeepSqlResource < Chef::Resource::LWRPBase
      provides :deepsql_service

      self.resource_name = :deepsql_service

      actions :create, :delete, :start, :stop
      default_action :create
      state_attrs :started, :created

      attribute :activation_key, kind_of: String, default: '000000000000000000000000000000000'
      attribute :bind_address, kind_of: String, default: nil
      attribute :charset, kind_of: String, default: 'utf8'
      attribute :data_dir, kind_of: String, default: nil
      attribute :default_storage_engine, kind_of: String, default: 'Deep'
      attribute :default_tmp_storage_engine, kind_of: String, default: 'Deep'
      attribute :error_log, kind_of: String, default: nil
      attribute :initial_root_password, kind_of: String, default: 'ilikerandompasswords'
      attribute :instance, kind_of: String, name_attribute: true
      attribute :mysqld_options, kind_of: Hash, default: {}
      attribute :package_action, kind_of: Symbol, default: :install
      attribute :package_name, kind_of: String, default: nil
      attribute :package_version, kind_of: String, default: nil
      attribute :pid_file, kind_of: String, default: nil
      attribute :port, kind_of: [String, Integer], default: '3306'
      attribute :run_group, kind_of: String, default: 'mysql'
      attribute :run_user, kind_of: String, default: 'mysql'
      attribute :socket, kind_of: String, default: nil
      attribute :tmp_dir, kind_of: String, default: nil
      attribute :version, kind_of: String, default: nil
      # sample how to specify an attribute is required...
      # attribute :your_auth, kind_of: [String, Array], required: true
      attribute :install_bundle_url, kind_of: String, default: nil
      attribute :repository_baseurl, kind_of: String, default: 'https://deepsql.s3.amazonaws.com/repository'
      attribute :enabled, kind_of: [TrueClass, FalseClass, NilClass], default: false
      attribute :installed, kind_of: [TrueClass, FalseClass, NilClass], default: false
    end
  end
end
