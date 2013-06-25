module Opencrx
  module Model
    class Account < Record
      have_attributes :aliasName

      def self.provider
        "#{base_provider}/account"
      end

      # subrecords of ours include :address
      def addresses
        query(:address)
      end
    end

    class FilteredAccount < Account
      def self.default_query_options
        query_type_option
      end
    end

    class LegalEntity < FilteredAccount
      have_attributes :name
    end

    class Contact < FilteredAccount; end
    class Group < FilteredAccount; end
    class UnspecifiedAccount < FilteredAccount; end
  end
end