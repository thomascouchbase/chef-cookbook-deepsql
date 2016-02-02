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

require 'spec_helper'

describe 'deepsql_test::single on ubuntu-14.04' do
  cached(:ubuntu_1404_service_56_single) do
    ChefSpec::SoloRunner.new(
      platform: 'ubuntu',
      version: '14.04',
      step_into: 'deepsql_test'
    ) do |node|
      node.set['deepsql']['version'] = '5.6.28'
    end.converge('deepsql_test::single')
  end

  context 'compiling the test recipe' do
    it 'creates deepsql_test[single]' do
      expect(ubuntu_1404_service_56_single).to create_deepsql_service('default')
    end
  end
end
