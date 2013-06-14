require 'rspec'
require 'opencrx'
require 'awesome_print'

describe Opencrx do
  before do
    Opencrx::connect("http://demo.opencrx.org", "guest", "guest")
  end

  context "Clients" do
    it "should login" do
      ap agent.contacts
      #ap agent.contact(".kMZjB3HEd6deJeK7BLpbw")
    end

    it "should updateX" do
      ap Opencrx::Contact.new(agent).updateX
    end

    it "should create" do
      ap Opencrx::Contact.new(agent).save
    end

    it "should query" do
      contacts = Opencrx::Account.query(size: 43)
      #ap contacts
      ap contacts.map(&:key)
    end

    it "should get" do
      contact =  Opencrx::Account.get('bf8036d9-d487-11e2-95d2-dd9cebe030de')
      #ap contact
      expect(contact['lastName']).to eq('ruby code')
    end

    it "should fail the get" do
      contact =  Opencrx::Contact.get('bf8036d9-d487-11e2-95d2-dd9cebe030deXX')
      expect(contact).to_not be
    end

  end
end
