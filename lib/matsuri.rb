require 'active_support/concern'

module Matsuri
  autoload :Config,   'matsuri/config'
  autoload :ShellOut, 'matsuri/shell_out'
  autoload :Registry, 'matsuri/registry'

  autoload :Task,     'matsuri/task'
  autoload :Cmd,      'matsuri/cmd'
  autoload :App,      'matsuri/app'

  module Kubernetes
    autoload :Base,                  'matsuri/kubernetes/base'
    autoload :Pod,                   'matsuri/kubernetes/pod'
    autoload :ReplicationController, 'matsuri/kubernetes/replication_controller'
    autoload :Service,               'matsuri/kubernetes/service'
    autoload :Endpoints,             'matsuri/kubernetes/endpoints'
    autoload :Secret,                'matsuri/kubernetes/secret'
  end

  module AddOns
    autoload :DNS, 'matsuri/add_ons/dns'
  end

  module Cmds
    autoload :Cli,     'matsuri/cmds/cli'
    autoload :K8s,     'matsuri/cmds/k8s'
    autoload :Show,    'matsuri/cmds/show'
    autoload :Start,   'matsuri/cmds/start'
    autoload :Reload,  'matsuri/cmds/reload'
    autoload :Restart, 'matsuri/cmds/restart'
    autoload :Stop,    'matsuri/cmds/stop'
  end

  module Tasks
    autoload :Kubernetes, 'matsuri/tasks/kubernetes'
    autoload :Docker,     'matsuri/tasks/docker'
    autoload :Pod,        'matsuri/tasks/pod'
  end

  module Concerns
    autoload :Await,           'matsuri/concerns/await'
    autoload :RegistryHelpers, 'matsuri/concerns/registry_helpers'
  end

  def self.define(*args, &blk)
    Matsuri::Registry.define(*args, &blk)
  end

  def self.environment
    Matsuri::Config.environment
  end

  def self.dev?
    Matsuri::Config.environment == 'dev'
  end

  def self.staging?
    Matsuri::Config.environment == 'staging'
  end

  def self.production?
    Matsuri::Config.environment == 'production'
  end

  def self.log(level, message)
    case level
    when :fatal then
      puts message
      exit(1)
    when :error, :warn then puts message
    when :info         then puts message if Matsuri::Config.verbose
    when :debug        then puts message if Matsuri::Config.debug
    end
  end
end
