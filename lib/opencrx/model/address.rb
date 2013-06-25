module Opencrx
  module Model
    class Address < Record
      # usage is a code
      USAGE = {
          mobile: "200",
          business: "500",
          fax: "530",
          visitor: "10500",
          other: "1800",
          delivery: "10200"
      }
      have_attributes :isMain, :disabled
      have_array_attributes :usage

      def self.provider
        "#{base_provider}/address"
      end

      def assign_to(parent)
        self.href = "#{parent.href}/address"
        self.identity = nil
      end
    end

    class PostalAddress < Address
      # postalCountry is a code
      COUNTRY = {
          de: "276"
      }
      have_attributes :postalCode, :postalCity, :postalState, :postalCountry
      have_array_attributes :postalAddressLine, :postalStreet
    end

    class EMailAddress < Address
      have_attributes :emailAddress
    end

    class PhoneNumber < Address
      have_attributes :phoneNumberFull, :automaticParsing
    end

    class WebAddress < Address
      have_attributes :webUrl
    end
  end
end