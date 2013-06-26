require 'opencrx/model/record/attributes'
require 'opencrx/model/record/query'

module Opencrx
  module Model
    class Record
      have_attributes :href, :identity, :modifiedAt, :createdAt, :userString0, :userString1, :userString2, :userString3

      def save
        url = href || self.class.query_url
        action = identity ? :put : :post
        response = Opencrx::session.send(action, url, body: to_xml)
        if (new_record = Result.parse(response)) && new_record.class == self.class
          self.attributes = new_record.attributes
          true
        else
          false
        end
      end

      def destroy
        response = Opencrx::session.delete(href)
        response.response.code == '204'
      end
    end
  end
end
