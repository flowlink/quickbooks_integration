module QBIntegration
  module Email
    def self.build(email_address)
      email = Quickbooks::Model::EmailAddress.new
      email.address = email_address
      email
    end
  end
end
