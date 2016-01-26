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

require 'chef/platform'

require_relative 'provider_systemd'
require_relative 'provider_sysvinit'
require_relative 'provider_upstart'

#########################################################################
# Chef::Resource::DeepSqlProviderSystemd Providers (centos, redhat)
#########################################################################

Chef::Platform.set(
    :platform => :centos,
    :version  => '>= 7.0',
    :resource => :deepsql_service,
    :provider => Chef::Provider::DeepSqlProviderSystemd
)

Chef::Platform.set(
    :platform => :redhat,
    :version  => '>= 7.0',
    :resource => :deepsql_service,
    :provider => Chef::Provider::DeepSqlProviderSystemd
)

#########################################################################
# Chef::Resource::DeepSqlProviderUpstart Providers (ubuntu)
#########################################################################

Chef::Platform.set(
    :platform => :ubuntu,
    :resource => :deepsql_service,
    :provider => Chef::Provider::DeepSqlProviderUpstart
)

#########################################################################
# Chef::Resource::DeepSqlProviderSysVinit Providers (default)
#########################################################################

Chef::Platform.set(
    :resource => :deepsql_service,
    :provider => Chef::Provider::DeepSqlProviderSysVinit
)
