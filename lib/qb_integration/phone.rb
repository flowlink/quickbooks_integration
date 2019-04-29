module QBIntegration
  module Phone
    def self.build(phonenumber)
      phone = Quickbooks::Model::TelephoneNumber.new
      phone.free_form_number = phonenumber
      phone
    end
  end
end
