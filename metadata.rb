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

name 'deepsql'
maintainer 'Deep Information Sciences, Inc.'
maintainer_email 'support@deepis.com'
license 'Apache 2.0'
description 'Library to install and configure deepSQL'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '3.3.0'

source_url 'https://github.com/chef-partners/netdev' if respond_to?(:source_url)
issues_url 'https://github.com/chef-partners/netdev/issues' if respond_to?(:issues_url)
