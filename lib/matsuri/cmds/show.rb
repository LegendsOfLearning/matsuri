require 'yaml'
require 'active_support/core_ext/hash/keys'

module Matsuri
  module Cmds
    class Show < Thor
      include Matsuri::Cmd

      class_option :json, aliases: :j, type: :boolean, default: false

      def self.show_cmd_for(resource_name)
        define_method(resource_name) do |name|
          show_resource { Matsuri::Registry.send(resource_name, name).new }
        end
      end

      desc 'config', 'displays config'
      def config
        with_config do |opt|
          puts opt.inspect if opt[:debug]
          conf = Matsuri::Config.save(true)
          platform = Matsuri::Platform.save(true)
          if options[:json]
            puts JSON.pretty_generate(conf), JSON.pretty_generate(platform)
          else
            puts conf.deep_stringify_keys.to_yaml, platform.deep_stringify_keys.to_yaml
          end
        end
      end

      desc 'dns', 'displays DNS Add On definition'
      def dns
        with_config do |opt|
          Matsuri::AddOns::DNS.show!(opt)
        end
      end

      desc 'pod POD_NAME [IMAGE_TAG]', 'show manifest for pod'
      def pod(name, image_tag='latest')
        show_resource { Matsuri::Registry.pod(name).new(image_tag: image_tag) }
      end

      desc 'rc RC_NAME [IMAGE_TAG]', 'show manifest for replication controller'
      def rc(name, image_tag = 'latest')
        show_resource { Matsuri::Registry.rc(name).new(image_tag: image_tag) }
      end

      desc 'service SERVICE_NAME', 'show manifest for service'
      show_cmd_for :services

      desc 'endpoints ENDPOINT_NAME', 'show manifest for endpoints'
      show_cmd_for :endpoints

      desc 'secret SECRET_NAME', 'show a secret'
      show_cmd_for :secret

      desc 'pv PV_NAME', 'show manifest for persistent volume'
      show_cmd_for :pv

      desc 'pvc PVC_NAME', 'show manifest for persistent volume claim'
      show_cmd_for :pvc

      desc 'storage_class STORAGE_CLASS_NAME', 'show manifest for storage class'
      show_cmd_for :storage_class

      private

      def show_resource
        with_config do |opt|
          resource = yield opt
          if options[:json]
            puts resource.pretty_print
          else
            puts resource.to_yaml
          end
        end
      end
    end
  end
end
