module Quickbooks
  module Windows
    class Client < Quickbooks::Base

      def persist

        return 200, {"key" => "value"}
      end

    end
  end
end