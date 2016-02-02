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

name             'deepsql_test'
maintainer       'Deep Information Sciences, Inc.'
maintainer_email 'bob@deepis.com'
license          'Apache License 2.0'
description      'Installs/Configures a demo to install deepSQL'
long_description 'Test cookbook for unit testing the deepSQL Cookbook.'
version          '1.0'

%w( amazon debian ubuntu centos redhat ).each do |os|
  supports os
end

depends 'deepsql'
