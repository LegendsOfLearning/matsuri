module Matsuri
  module Kubernetes
    class Deployment < Matsuri::Kubernetes::Base
      include Matsuri::Concerns::Scalable

      let(:api_version) { 'extensions/v1beta1' } # http://kubernetes.io/docs/api-reference/extensions/v1beta1/definitions/#_v1beta1_deployment
      let(:kind)        { 'Deployment' }         # http://kubernetes.io/docs/user-guide/deployments/

      # Overridables

      let(:default_metadata) { { name: maybe_param_name, namespace: namespace, labels: final_labels, annotations: annotations } }
      let(:spec) do
        {
          replicas: replicas,
          selector: selector,
          template: template,
          strategy: strategy,
          minReadySeconds: min_ready_seconds,
          revisionHistoryLimit: revision_history_limit
        }.compact
      end

      let(:selector) { { matchLabels: match_labels, matchExpressions: match_expressions } }

      # Parameters passed from command line
      # These are here to support rolling updates
      # Copied from ReplicationController, but
      # Don't know if we are going to keep this around
      let(:maybe_param_name)     { options[:name] || name }
      let(:maybe_param_replicas) { options[:relicas] || replicas }
      let(:image_tag)            { options[:image_tag] || 'latest' }

      # Explicitly define replicas
      let(:replicas)          { fail NotImplementedError, 'Must define let(:replicas)' }
      let(:match_labels)      { fail NotImplementedError, 'Must define let(:match_labels)' }

      let(:match_expressions) { [] }

      # By default, point the template to an existing pod definition
      # Overide let(:pod_name)
      let(:template) { { metadata: { labels: pod_def.labels, annotations: pod_def.annotations }, spec: pod_def.spec } }

      # Deployment Strategy. Defaults to Rolling Update. Recreate is the other one.
      let(:strategy) { { type: 'RollingUpdate', rollingUpdate: rolling_update } }
      let(:rolling_update) { { maxUnavailable: max_unavailable, maxSurge: max_surge } }
      # See: http://kubernetes.io/docs/api-reference/extensions/v1beta1/definitions/#_v1beta1_rollingupdatedeployment
      let(:max_unavailable) { 1 }
      let(:max_surge)       { 1 }

      # Minimum number of seconds for which a newly created pod should be ready without
      # any of its container crashing, for it to be considered available.
      # Defaults to 0 (pod will be considered available as soon as it is ready)
      let(:min_ready_seconds) { 0 }

      # The number of old ReplicaSets to retain to allow rollback. This is a pointer to
      # distinguish between explicit zero and not specified.
      let(:revision_history_limit) { nil }

      # Define this to point to an existing pod definition. This is the name
      # registered to Matsuri::Registry
      let(:pod_name)          { fail NotImplementedError, 'Must define let(:pod_name)' }
      let(:pod_def)           { pod(pod_name, image_tag: image_tag, release: release) }
      let(:primary_image)     { pod_def.primary_image }
      let(:primary_container) { pod_def.primary_container }

      ### Helpers
      def update!(version: nil)
        version ||= self.image_tag
        rollout! versions: { primary_container => "#{primary_image}:#{version}" }
      end

      def rollout!(versions:)
        version_changes = versions.map { |(k,v)| "#{k}=#{v}" }.join(' ')
        kubectl! "set image #{resource_type}/#{name} #{version_changes} --record=true"
      end

      def watch_rollout!
        kubectl! "rollout status #{resource_type}/#{name}"
      end

      ### @TODO Factor this out into helpers

      # @TODO This assumes the first container is the primary container
      def current_image
        manifest = current_manifest
        return nil unless manifest
        containers = manifest.get(:spec, :template, :spec, :containers)
        return nil unless containers.any?
        containers[0].get(:image)
      end

      def current_image_tag
        image = current_image or return nil
        image.split(/:/).last
      end

      def selected_pods_json
        fail NotImpelemntedError, 'Match Expressions not yet implemented' if Array(match_expressions).any?
        sel = match_labels.to_a.map { |(k,v)| "#{k}=#{v}" }.join(',')
        cmd = kubectl "get pods -l #{sel} -o json", echo_level: :debug, no_stdout: true
        JSON.parse(cmd.stdout)
      end

      def selected_pods
        selected_pods_json['items']
      end

      class << self
        def load_path
          Matsuri::Config.deployments_path
        end

        def definition_module_name
          'Deployments'
        end
      end
    end
  end
end
