module Matsuri
  module Kubernetes
    # Kubernetes Persistant Volume
    class PersistantVolume < Matsuri::Kubernetes::Base
      let(:kind)                { 'PersistentVolume' }
      let(:default_annotations) { { 'volume.beta.kubernetes.io/storage-class' => storage_class } } # http://kubernetes.io/docs/user-guide/persistent-volumes/

      let(:spec) do
        {
          capacity:                      capacity,
          accessModes:                   access_modes,
          persistantVolumeReclaimPolicy: reclaim_policy
        }.merge(plugin_spec)
      end

      let(:storage_class)       { fail NotImplementedError, 'Must define let(:storage_class)' }
      let(:access_modes)        { fail NotImplementedError, 'Must define let(:access_modes): ReadWriteOnce, ReadOnlyMany, ReadWriteMany' }
      let(:capacity)            { { storage: storage_size } } # http://kubernetes.io/docs/user-guide/persistent-volumes/#capacity
      let(:storage_size)        { fail NotImplementedError, 'Must define let(:storage_size)' }
      let(:reclaim_policy)      { fail NotImplementedError, 'Must define let(:reclaime_policy): Retain, Recycle, Delete' }
      let(:plugin_spec)         { fail NotImplementedError, 'Must define let(:public_spec). Ex: gce_persistant_disk' }

      # GCE peristant disk plugin
      # http://kubernetes.io/docs/api-reference/v1/definitions/#_v1_gcepersistentdiskvolumesource
      let(:gce_persistant_disk) do
        {
          pdName:    gce_pd_name,
          fsType:    gce_fstype,
          partition: gce_partition,
          read_only: gce_read_only?

        }.compact
      end

      let(:gce_pd_name)    { fail NotImplementedError, 'Must define let(:gce_pd_name) to unique PD resource on GCE' }
      let(:gce_fstype)     { 'ext4' } # Examples: ext4, xfs, ntfs
      let(:gce_partition)  { nil }
      let(:gce_read_only?) { false }
    end
  end
end
