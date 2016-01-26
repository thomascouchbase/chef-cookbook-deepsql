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

      attribute :app_name, :kind_of => String, :name_attribute => true
      attribute :remote_file, :kind_of => String, :default => nil
      attribute :cookbook_file, :kind_of => String, :default => nil
      attribute :cookbook, :kind_of => String, :default => nil
      attribute :checksum, :kind_of => String, :default => nil
      attribute :remote_directory, :kind_of => String, :default => nil
      attribute :activation_key, :kind_of => String, :required => true
      attribute :app_dependencies, :kind_of => Array, :default => []
      attribute :templates, :kind_of => [Array, Hash], :default => []
      attribute :enabled, :kind_of => [TrueClass, FalseClass, NilClass], :default => false
      attribute :installed, :kind_of => [TrueClass, FalseClass, NilClass], :default => false
    end
  end
end
