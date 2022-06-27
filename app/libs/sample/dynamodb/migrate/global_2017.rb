module Sample::Dynamodb
  class Migrate::Global2017 < Migration
    def key_schema
      [{ attribute_name: :user_id, key_type: 'HASH' }]
    end

    def attribute_definitions
      [{ attribute_name: :user_id, attribute_type: 'S' }]
    end

    def global_table_enabled
      true
    end

    def replica_enabled
      false
    end

    def replica_regions
      ['ap-northeast-1', 'us-west-2']
    end
  end
end
