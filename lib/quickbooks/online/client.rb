module Quickbooks
  module Online
    class Client < Quickbooks::Base
      def status_service
        not_supported!
      end
    end
  end
end