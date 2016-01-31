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

    def deepsql_name
      "deepsql-#{new_resource.instance}"
    end

    def defaults_file
      "#{etc_dir}/my.cnf"
    end

    def error_log
      return new_resource.error_log if new_resource.error_log
      "#{log_dir}/error.log"
    end

    def etc_dir
      "/etc/#{deepsql_name}"
    end

    def include_dir
      "#{etc_dir}/conf.d"
    end

    def lc_messages_dir
      '/usr/share/mysql'
    end

    def log_dir
      "/var/log/#{deepsql_name}"
    end

    def parsed_data_dir
      return new_resource.data_dir if new_resource.data_dir
      return "/var/lib/#{deepsql_name}" if node['os'] == 'linux'
    end

    def run_dir
      "/var/run/#{deepsql_name}"
    end

    def pid_file
      return new_resource.pid_file if new_resource.pid_file
      "#{run_dir}/mysqld.pid"
    end

    def socket_dir
      return File.dirname(new_resource.socket) if new_resource.socket
      run_dir
    end

    def socket_file
      return new_resource.socket if new_resource.socket
      "#{run_dir}/mysqld.sock"
    end

    def system_service_name
      return 'mysqld' if node['platform_family'] == 'rhel'
      'mysql'
    end

    def tmp_dir
      return new_resource.tmp_dir if new_resource.tmp_dir
      '/tmp'
    end

    def parsed_version
      new_resource.version if new_resource.version
      # TODO: add per platform defaults
    end

    def v56plus
      return false if parsed_version.split('.')[0].to_i < 5
      return false if parsed_version.split('.')[1].to_i < 6
      true
    end

    def v57plus
      return false if parsed_version.split('.')[0].to_i < 5
      return false if parsed_version.split('.')[1].to_i < 7
      true
    end

    def mysqld_bin
      '/usr/sbin/mysqld'
    end

    def mysql_install_db_bin
      'mysql_install_db'
    end

    def mysqld_safe_bin
      '/usr/bin/mysqld_safe'
    end

    # locally test:
    #
    # /usr/sbin/mysqld --defaults-file=/etc/deepsql-deep/my.cnf --initialize --explicit_defaults_for_timestamp
    def mysqld_initialize_cmd
      cmd = mysqld_bin
      cmd << " --defaults-file=#{etc_dir}/my.cnf"
      cmd << ' --initialize'
      cmd << ' --explicit_defaults_for_timestamp' if v56plus
      cmd
    end

    def mysql_install_db_cmd
      cmd = mysql_install_db_bin
      cmd << " --defaults-file=#{etc_dir}/my.cnf"
      cmd << " --datadir=#{parsed_data_dir}"
      cmd << ' --explicit_defaults_for_timestamp' if v56plus
      cmd
    end

    def db_init
      return mysqld_initialize_cmd if v57plus
      mysql_install_db_cmd
    end

    def record_init
      cmd = v56plus ? mysqld_bin : mysqld_safe_bin
      cmd << " --defaults-file=#{etc_dir}/my.cnf"
      cmd << " --init-file=/tmp/#{deepsql_name}/my.sql"
      cmd << ' --explicit_defaults_for_timestamp' if v56plus
      cmd << ' &'
      cmd
    end

    def password_column_name
      return 'authentication_string' if v57plus
      'password'
    end

    def password_expired
      return ", password_expired='N'" if v57plus
      ''
    end

    def init_records_script
      <<-EOS
        set -e
        rm -rf /tmp/#{deepsql_name}
        mkdir /tmp/#{deepsql_name}

        cat > /tmp/#{deepsql_name}/my.sql <<-EOSQL
UPDATE mysql.user SET #{password_column_name}=PASSWORD('#{root_password}')#{password_expired} WHERE user = 'root';
DELETE FROM mysql.user WHERE USER LIKE '';
DELETE FROM mysql.user WHERE user = 'root' and host NOT IN ('127.0.0.1', 'localhost');
FLUSH PRIVILEGES;
DELETE FROM mysql.db WHERE db LIKE 'test%';
DROP DATABASE IF EXISTS test ;
EOSQL

      #{db_init}
      #{record_init}
      EOS
    end
  end
end
