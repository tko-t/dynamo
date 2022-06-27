module Sample::Dynamodb
  class Migrate::Sample < Migration
    def key_schema
      [{ attribute_name: :user_id, key_type: 'HASH' }]
    end

    def attribute_definitions
      [{ attribute_name: :user_id, attribute_type: 'S' }]
    end
  end
end
