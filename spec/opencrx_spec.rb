require 'rspec'
require 'opencrx'
require 'awesome_print'

describe Opencrx do
  let(:agent) { Opencrx::Agent.new("http://guest:guest@demo.opencrx.org") }
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

    it "should get" do
      ap Opencrx::Contact.new(agent).get('bf8036d9-d487-11e2-95d2-dd9cebe030de')
    end

  end
end
