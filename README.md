deepSQL Cookbook
=======================

The deepSQL Cookbook is a library cookbook that provides resource primitives
(LWRPs) for use in recipes. It is designed to be a reference example for
creating highly reusable cross-platform cookbooks.

Requirements
------------
- Chef 11 or higher
- Ruby 1.9 or higher (preferably from the Chef full-stack installer)
- Network accessible package repositories

Platform Support
----------------
The following platforms have been tested with Test Kitchen:

```
|----------------+-----+-----+-----+-----+-----|
|                | 5.0 | 5.1 | 5.5 | 5.6 | 5.7 |
|----------------+-----+-----+-----+-----+-----|
| debian-7       |     |     |     |     |     |
|----------------+-----+-----+-----+-----+-----|
| ubuntu-12.04   |     |     | X   | X   |     |
|----------------+-----+-----+-----+-----+-----|
| ubuntu-14.04   |     |     | X   | X   |     |
|----------------+-----+-----+-----+-----+-----|
| ubuntu-15.04   |     |     |     |     |     |
|----------------+-----+-----+-----+-----+-----|
| centos-5       |     |     |     |     |     |
|----------------+-----+-----+-----+-----+-----|
| centos-6       |     |     | X   | X   |     |
|----------------+-----+-----+-----+-----+-----|
| centos-7       |     |     | X   | X   |     |
|----------------+-----+-----+-----+-----+-----|
| amazon         |     |     |     |     |     |
|----------------+-----+-----+-----+-----+-----|
| fedora-21      |     |     |     |     |     |
|----------------+-----+-----+-----+-----+-----|
| fedora-22      |     |     |     |     |     |
|----------------+-----+-----+-----+-----+-----|
```

Usage
-----
Place a dependency on the deepsql cookbook in your cookbook's metadata.rb

```ruby
depends 'deepsql', '~> 3.3'
```

Then, in a recipe:

```ruby
deepsql_service 'foo' do
  port '3306'
  version '3.3'
  initial_root_password 'change me'
  action [:create, :start]
end
```

The service name on the OS is `deepsql-foo`. You can manually start and
stop it with `service deepsql-foo start` and `service deepsql-foo stop`.

The configuration file is at `/etc/deepsql-foo/my.cnf`. It contains the
minimum options to get the service running. It looks like this.

Resources Overview
----------
### deepsql_service

The `deepsql_service` resource manages the basic plumbing needed to get a
deepSQL server instance running with minimal configuration.

The `:create` action handles package installation, support
directories, socket files, and other operating system level concerns.
The internal configuration file contains just enough to get the
service up and running, then loads extra configuration from a conf.d
directory. Further configurations are managed with the `deepsql_config` resource.

- If the `data_dir` is empty, a database will be initialized, and a
root user will be set up with `initial_root_password`. If this
directory already contains database files, no action will be taken.

The `:start` action starts the service on the machine using the
appropriate provider for the platform. The `:start` action should be
omitted when used in recipes designed to build containers.

#### Example
```ruby
deepsql_service 'default' do
  version '3.3'
  bind_address '0.0.0.0'
  port '3306'
  data_dir '/data'
  initial_root_password 'Ch4ng3me'
  action [:create, :start]
end
```

#### Parameters

- `charset` - specifies the default character set. Defaults to `utf8`.

- `data_dir` - determines where the actual data files are kept
on the machine. This is useful when mounting external storage. When
omitted, it will default to the platform's native location.

- `error_log` - Tunable location of the error_log

- `initial_root_password` - allows the user to specify the initial
  root password for mysql when initializing new databases.
  This can be set explicitly in a recipe, driven from a node
  attribute, or from data_bags. When omitted, it defaults to
  `ilikerandompasswords`. Please be sure to change it.

- `instance` - A string to identify the deepSQL service. By convention,
  to allow for multiple instances of the `deepsql_service`, directories
  and files on disk are named `deepsql-<instance_name>`. Defaults to the
  resource name.

- `package_action` - Defaults to `:install`.

- `package_name` - Defaults to a value looked up in an internal map.

- `package_version` - Specific version of the package to install,
  passed onto the underlying package manager. Defaults to `nil`.

- `bind_address` - determines the listen IP address for the mysqld service. When
  omitted, it will be determined by deepSQL. If the address is "regular" IPv4/IPv6
  address (e.g 127.0.0.1 or ::1), the server accepts TCP/IP connections only for
  that particular address. If the address is "0.0.0.0" (IPv4) or "::" (IPv6), the
  server accepts TCP/IP connections on all IPv4 or IPv6 interfaces.

- `mysqld_options` - A key value hash of options to be rendered into
  the main my.cnf. WARNING - It is highly recommended that you use the
  `mysql_config` resource instead of sending extra config into a
  `deepsql_service` resource. This will allow you to set up
  notifications and subscriptions between the service and its
  configuration. That being said, this can be useful for adding extra
  options needed for database initialization at first run.

- `port` - determines the listen port for the mysqld service. When
  omitted, it will default to '3306'.

- `run_group` - The name of the system group the `deepsql_service`
  should run as. Defaults to 'mysql'.

- `run_user` - The name of the system user the `deepsql_service` should
  run as. Defaults to 'mysql'.

- `pid_file` - Tunable location of the pid file.

- `socket` - determines where to write the socket file for the
  `deepsql_service` instance. Useful when configuring clients on the
  same machine to talk over socket and skip the networking stack.
  Defaults to a calculated value based on platform and instance name.

- `tmp_dir` - Tunable location of the tmp_dir

- `version` - allows the user to select from the versions available
  for the platform, where applicable. When omitted, it will install
  the default DeepSQL version for the target platform. Available version
  numbers are `5.0`, `5.1`, `5.5`, `5.6`, and `5.7`, depending on platform.

#### Actions

- `:create` - Configures everything but the underlying operating system service.
- `:delete` - Removes everything but the package and data_dir.
- `:start` - Starts the underlying operating system service
- `:stop`-  Stops the underlying operating system service
- `:restart` - Restarts the underlying operating system service
- `:reload` - Reloads the underlying operating system service

Please note that when using `notifies` or `subscribes`, the resource
to reference is `deepsql_service[name]`, not `service[deepsql]`.

#### Providers
Chef selects the appropriate provider based on platform and version,
but you can specify one if your platform support it.

```ruby
deepsql_service[instance-1] do
  port '1234'
  data_dir '/mnt/lottadisk'
  provider Chef::Provider::DeepSqlProviderSysVinit
  action [:create, :start]
end
```

- `Chef::Provider::DeepSqlProviderBase` - Configures everything needed to run
a deepSQL service except the platform service facility. This provider
should never be used directly. The `:start`, `:stop`, `:restart`, and
`:reload` actions are stubs meant to be overridden by the providers
below.

- `Chef::Provider::DeepSqlProviderSystemd` - Starts a `deepsql_service`
using SystemD. Manages the unit file and activation state

- `Chef::Provider::DeepSqlProviderSysVinit` - Starts a `deepsql_service`
using SysVinit. Manages the init script and status.

- `Chef::Provider::DeepSqlProviderUpstart` - Starts a `deepsql_service`
using Upstart. Manages job definitions and status.

Advanced Usage Examples
-----------------------
There are a number of configuration scenarios supported by the use of
resource primitives in recipes. For example, you might want to run
multiple DeepSQL services, as different users, and mount block devices
that contain pre-existing databases.

### Multiple Instances as Different Users

```ruby
# instance-1
user 'alice' do
  action :create
end

directory '/mnt/data/mysql/instance-1' do
  owner 'alice'
  action :create
end

mount '/mnt/data/mysql/instance-1' do
  device '/dev/sdb1'
  fstype 'ext4'
  action [:mount, :enable]
end

deepsql_service 'instance-1' do
  port '3307'
  run_user 'alice'
  data_dir '/mnt/data/mysql/instance-1'
  action [:create, :start]
end

mysql_config 'site config for instance-1' do
  instance 'instance-1'
  source 'instance-1.cnf.erb'
  notifies :restart, 'deepsql_service[instance-1]'
end

# instance-2
user 'bob' do
  action :create
end

directory '/mnt/data/mysql/instance-2' do
  owner 'bob'
  action :create
end

mount '/mnt/data/mysql/instance-2' do
  device '/dev/sdc1'
  fstype 'ext3'
  action [:mount, :enable]
end

deepsql_service 'instance-2' do
  port '3308'
  run_user 'bob'
  data_dir '/mnt/data/mysql/instance-2'
  action [:create, :start]
end

mysql_config 'site config for instance-2' do
  instance 'instance-2'
  source 'instance-2.cnf.erb'
  notifies :restart, 'deepsql_service[instance-2]'
end
```

### Replication Testing
Use multiple `deepsql_service` instances to test a replication setup.
This particular example serves as a smoke test in Test Kitchen because
it exercises different resources and requires service restarts.

https://github.com/chef-cookbooks/mysql/blob/master/test/fixtures/cookbooks/mysql_replication_test/recipes/default.rb

Frequently Asked Questions
--------------------------

### How do I run this behind my firewall?

On Linux, the `deepsql_service` resource uses the platform's underlying
package manager to install software. For this to work behind
firewalls, you'll need to either:

- Configure the system yum/apt utilities to use a proxy server that
  can reach the Internet
- Host a package repository on a network that the machine can talk to

On the RHEL platform_family, applying the `yum::default` recipe will
allow you to drive the `yum_globalconfig` resource with attributes to
change the global yum proxy settings.

### How do I check AppArmor profiles?

```
  apt-get install apparmor-utils
  dmesg --clear
  /usr/sbin/mysqld --defaults-file=/etc/deepsql-deep/my.cnf --initialize --explicit_defaults_for_timestamp
  dmesg
  aa-logprof
```

License & Authors
-----------------
- Author:: Robert Buck (<buck.robert.j@gmail.com>)

```text
Copyright:: 2016 Deep Information Sciences, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
