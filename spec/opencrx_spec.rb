require 'rspec'
require 'opencrx'
require 'awesome_print'

describe Opencrx do
  before do
    Opencrx::connect("http://demo.opencrx.org", "guest", "guest")
  end

  context "Clients" do
    it "should create" do
      lastName = Time.now.to_s
      contact = Opencrx::Account::Contact.new(lastName: lastName).save
      expect(contact.class).to eq(Opencrx::Account::Contact)
      expect(contact['lastName']).to eq(lastName)
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

    it "should get and convert back to xml and save" do
      contact =  Opencrx::Account.get('bf8036d9-d487-11e2-95d2-dd9cebe030de')
      contact['firstName'] = Time.now.to_s
      #ap contact
      #puts contact.xml
      # really expect the date to show up
      expect(contact.dup.save).to eq(contact)
    end

    it "should fail the get" do
      contact =  Opencrx::Contact.get('bf8036d9-d487-11e2-95d2-dd9cebe030deXX')
      expect(contact).to_not be
    end

  end
end
