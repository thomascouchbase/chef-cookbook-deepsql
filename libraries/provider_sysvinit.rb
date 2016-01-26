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
    class DeepSqlProviderSysVinit < DeepSqlProviderBase

      provides :deepsql_service, :os => '!windows' if defined?(provides)

      action :create do
        Chef::Log.info("SysVinit::Create")
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
