module Sample::Dynamodb
  class Apis
    include Client

    class << self
      def put_item(table_name, item, region = nil)
        new.client(region).put_item({
          table_name:,
          item:,
        })
      end

      def get_item(table_name, key, region = nil)
        new.client(region).get_item(
          table_name:,
          key:,
        ).item || {}
      end

      def list_global_tables(region: nil)
        new.client(region).list_global_tables
      end

      def describe_table_replica_auto_scaling(table_name, region: nil)
        new.client(region).describe_table_replica_auto_scaling( { table_name: })
      end

      def info(table_name, region: nil)
        new.client(region).describe_table(table_name: )
      end

      def list_tables(region: nil)
        new.client(region).list_tables
      end
    end
  end
end
