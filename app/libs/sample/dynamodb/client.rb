module Sample::Dynamodb
  module Client
    def credentials
      Aws::Credentials.new('dummy','dummy')
    end

    def default_region
      'ap-northeast-1'
    end

    def client(region = nil)
      SingletonClient.instance.client(region || default_region, credentials)
    end

    class SingletonClient
      include Singleton

      def client(region, credentials)
        (@clients ||= {})[region] ||= ::Aws::DynamoDB::Client.new(region:, credentials:, endpoint: 'http://localstack:4566')
      end

      def refresh_client(region, credentials)
        (@clients ||= {})[region] = ::Aws::DynamoDB::Client.new(region:, credentials:)
      end
    end
  end
end
