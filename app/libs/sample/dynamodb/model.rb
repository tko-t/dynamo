module Sample::Dynamodb
  class Model
    include Client

    class << self
      def get(key, table_name: nil, region: nil)
        new(table_name, region).get(key)
      end

      def put(item, table_name: nil, region: nil)
        new(table_name, region).put(item)
      end
    end

    def initialize(table_name, region)
      @table_name = table_name
      @region = region
    end

    def get(key)
      Apis.get_item(table_name, key, region)
    end

    def put(item)
      Apis.put_item(table_name, item, region)
    end

    def region
      @region ||= default_region
    end

    def table_name
      @table_name ||= self.class.name.demodulize.underscore
    end
  end
end
