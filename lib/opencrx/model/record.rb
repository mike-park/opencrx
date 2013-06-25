require 'opencrx/model/record/attributes'
require 'opencrx/model/record/query'

module Opencrx
  module Model
    class Record
      have_attributes :href, :identity

      def save
        href = attributes['href'] || self.class.query_url
        response = if attributes['identity']
                     Opencrx::session.put(href, body: to_xml)
                   else
                     Opencrx::session.post(href, body: to_xml)
                   end
        Result.parse(response)
      end

      # TODO implement delete
      def destroy
        href = attributes['href']
        # this errors with No active unit of work
        #Opencrx::session.delete(href, body: to_xml)
        # this errors with Premature end of file.
        #Opencrx::session.delete(href)
      end
    end
  end
end
