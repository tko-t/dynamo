module Sample::Dynamodb
  class Migration
    include Client

    ATTRIBUTES = %i[
      table_name
      key_schema
      attribute_definitions
      provisioned_throughput
      billing_mode
      tags
      stream_specification
      sse_specification
      kms_master_key_id
      region
      stream_enabled
      sse_enabled
      backup_enabled
      global_table_enabled
      replica_enabled
      replica_regions]

    class << self
      def create(**args)
        migrator = new(**args)
        migrator.__send__(:create)
        migrator.__send__(:description)
        migrator
      end

      def drop(**args)
        migrator = new(**args)
        migrator.__send__(:drop)
        migrator.__send__(:description)
        migrator
      end

      def exists?(**args)
        migrator = new(**args)
        migrator.__send__(:exists?)
      end
    end

    # ATTRIBUTES にあるものだけをインスタンス変数にセット
    def initialize(**args)
      self.class::ATTRIBUTES.each do |attr|
        instance_variable_set("@#{attr}", args[attr])
      end
    end

    # overwritable

    def region
      @region ||= default_region # default is client#default_region
    end

    # required
    def table_name
      @table_name ||= self.class.name.demodulize.underscore
    end

    # required
    # override or param or fail
    def key_schema
      @key_schema || raise('Not implemented yet!')
    end

    # required
    # override or param or fail
    def attribute_definitions
      @attribute_definitions || raise('Not implemented yet!')
    end

    # required when mode PROVISIONED
    def provisioned_throughput
      (@provisioned_throughput || raise('Not implemented yet!')) if provisioned?
    end

    # optional PAY_PER_REQUEST | PROVISIONED
    # default PAY_PER_REQUEST
    def billing_mode
      @billing_mode ||= 'PAY_PER_REQUEST'
    end

    # optional
    def tags
      @tags ||= [
        {
          key: 'created_at',
          value: Date.today.to_s
        }, {
          key: 'env',
          value: Rails.env
        }
      ]
    end

    # create an AWS managed key first
    def kms_master_key_id
      @kms_master_key_id ||= 'alias/aws/dynamodb'
    end

    # optional
    # default true
    def stream_specification
      @stream_specification || {
        stream_enabled: true,
        stream_view_type: 'NEW_AND_OLD_IMAGES'
      }
    end

    # optional
    # default true
    def sse_specification
      @sse_specification || {
        enabled: true,
        sse_type: 'KMS',
        kms_master_key_id:,
      }
    end

    def stream_enabled
      @stream_enabled
    end

    def sse_enabled
      @sse_enabled
    end

    def backup_enabled
      @backup_enabled
    end

    def global_table_enabled
      @global_table_enabled
    end

    def replica_enabled
      @replica_enabled
    end

    def replica_regions
      @replica_regions ||= ['us-west-2']
    end

    private

    def create
      # レプリカとグローバルテーブルは共存できない
      raise "only replica or global table" if replica_enabled && global_table_enabled

      if global_table_enabled # レプリカの作成(ver. 2017.11.29)
        # 2017.11.29 のレプリカは、それぞれのリージョンにテーブルを作成する
        replica_regions.each {|replica_region| create_table(region: replica_region) }
        create_global_table
      else
        create_table(region:) # テーブル作成
      end

      update_continuous_backup if backup_enabled  # ポイントインタイムリカバリ設定
      create_replica if replica_enabled           # レプリカの作成(ver. 2019.11.21)
    end

    def drop
      delete_replica if use_replica?  # レプリカテーブルがあれば先に削除

      if use_global_table?  # グローバルテーブルがある場合はそれぞれ削除
        replica_regions.each {|region| delete_table(region:) }
      else
        delete_table(region:) # テーブル削除
      end
    end

    def description
      exists = Apis.list_tables.table_names.include?(table_name)
      @description = { table_name.to_sym => { exists: exists } }
      @description.merge!(Apis.info(table_name, region:).table) if exists
    end

    def exists?
      Apis.list_tables.table_names.include?(table_name)
    end

    # テーブル作成
    def create_table(region: nil)
      client(region).create_table(create_params)
      client(region).wait_until(:table_exists, table_name:)
    end

    # テーブル削除
    def delete_table(region: nil)
      client(region).delete_table({ table_name: })
      client(region).wait_until(:table_not_exists, table_name:)
    end

    # ポイントインタイムリカバリ (PITR)の設定
    def update_continuous_backup
      client(region).update_continuous_backups(
        table_name:,
        point_in_time_recovery_specification: {
          point_in_time_recovery_enabled: true
        })
    end

    # レプリカ作成(グローバルテーブル)
    # ver. 2017
    def create_global_table
      client(region).create_global_table({
        global_table_name: table_name,
        replication_group: replica_regions.map {|replica_region|
          { region_name: replica_region }
        }
      })
    end

    # レプリカ作成
    # ver. 2019
    def create_replica
      parameters = {
        replica_updates: replica_regions.map {|replica_region|
          {
            create: {
              region_name: replica_region
            }
          }
        }
      }
      update_table(parameters)

      replica_regions.each do |replica_region|
        client(replica_region).wait_until(:table_exists, table_name:)
      end
    end

    # レプリカ削除
    # ver. 2019
    def delete_replica
      parameters = {
        replica_updates: replica_regions.map {|replica_region|
          {
            delete: {
              region_name: replica_region
            }
          }
        }
      }
      update_table(parameters)

      # テーブルが消えるまで待つ
      replica_regions.each do |replica_region|
        client(replica_region).wait_until(:table_not_exists, table_name:)
      end

      # レプリカが消えるのも待つ
      until_replica_not_exists
    end

    def update_table(parameters)
      client(region).update_table({
        table_name:,
        **parameters
      })
    end

    # 2019
    def use_replica?
      replicas.present?
    end

    def until_replica_not_exists
      count = 0
      max_count = 240 # 最大2分

      while replicas.present? do
        break if max_count <= (count += 1).tap { print "\r#{count}" }
        sleep 0.5
      end

      raise "timeout delete replica" if replicas.present?
    end

    def replicas
      Apis.info(table_name, region:).table.replicas
    end

    def use_global_table?
      global_tables.present?
    end

    # 2017
    def global_tables
      #Apis.list_global_tables(table_name, region:).global_tables
      Apis.list_global_tables.global_tables.find{|gt| gt.global_table_name == table_name }
    end

    def provisioned?
      billing_mode == 'PROVISIONED'
    end

    def create_params
      params = {
        table_name:,            # required
        key_schema:,            # required
        attribute_definitions:, # required
        billing_mode:,          # optional. default PAY_PER_REQUEST
        tags:                   # optional
      }

      params.merge!({ stream_specification: })   if stream_enabled # optional default enable
      params.merge!({ sse_specification: })      if sse_enabled    # optional default enable
      params.merge!({ provisioned_throughput: }) if provisioned?   # optional default disable
      params
    end
  end
end
