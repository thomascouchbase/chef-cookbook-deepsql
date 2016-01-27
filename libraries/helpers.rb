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

require 'shellwords'
require 'chef/mixin/shell_out'

module DeepSql
  module Helper
    include Chef::Mixin::ShellOut

    def pretty_print_updated_values(updated_values)
      updated_values.map do |key, value|
        "#{key}: #{value}"
      end.join(', ')
    end

    def generate_command_opts
      opts = []
      new_resource.state_attrs.each do |a|
        current_val = current_resource.send(a)
        new_val     = new_resource.send(a)
        opts << "--#{a} #{new_val}" if updated?(current_val, new_val)
      end
      opts
    end

    def updated?(current_val, new_val)
      (current_val != new_val) && !new_val.nil?
    end

    def execute_command(command)
      output = shell_out!(command)
      output.stdout
    end

    def root_password
      if new_resource.initial_root_password == ''
        Chef::Log.info('Root password is empty')
        return ''
      end
      Shellwords.escape(new_resource.initial_root_password)
    end

  end
end
