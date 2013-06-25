# encoding: utf-8
require 'spec_helper'

describe Opencrx do
  let(:vcr_options) { {match_requests_on: [:method, :path, :query, :body]} }

  before do
    #Opencrx::connect("https://www.krypton.de", "guest", "guest")
    Opencrx::connect("http://localhost:8080", "guest", "guest")
  end

  context "initial opencrx installation" do
    it "should find at least one email address" do
      VCR.use_cassette('session/address', vcr_options) do
        result_set = Opencrx::session.get("/org.opencrx.kernel.account1/provider/CRX/segment/Standard/address")
        expect(result_set.length).to have_at_least(1).items
      end
    end

    it "should find at least one account" do
      VCR.use_cassette('session/account', vcr_options) do
        result_set = Opencrx::session.get("/org.opencrx.kernel.account1/provider/CRX/segment/Standard/account")
        expect(result_set.length).to have_at_least(1).items
      end
    end
  end

  context Opencrx::Model::Record do
    context "attributes" do
      let(:opencrx) { {
          "a" => 1,
          "list1" => {"_item" => 'one item'},
          "list2" => {"_item" => %w(one two)},
          "complex" => {"__content__" => "ignore me", "href" => "http://somewhere"}
      } }
      let(:local) { {
          a: 1,
          list1: ['one item'],
          list2: %w(one two)
      } }

      def expect_match(record)
        expect(record.attribute(:a)).to eq(1)
        expect(record.attribute(:list1)).to eq(['one item'])
        expect(record.attribute('list2')).to eq(['one', "two"])
      end

      it "should remap opencrx xml to attributes" do
        record = Opencrx::Model::Record.new(opencrx)
        expect_match(record)
      end

      it "should store local attributes as expected" do
        record = Opencrx::Model::Record.new(local)
        expect_match(record)
      end

      it "should generate xml" do
        xml =<<EOF
<?xml version="1.0" encoding="UTF-8"?>
<org.opencrx.kernel.account1.Record>
  <a type="integer">1</a>
  <list1 type="array">
    <_item>one item</_item>
  </list1>
  <list2 type="array">
    <_item>one</_item>
    <_item>two</_item>
  </list2>
</org.opencrx.kernel.account1.Record>
EOF
        record = Opencrx::Model::Record.new(opencrx)
        expect(record.to_xml).to eq(xml)
      end
    end
  end

  context Opencrx::Model::LegalEntity do

    context "create, find, update" do
      let(:name) { "AA äöëïöü" }

      it "should create with umlauts" do
        VCR.use_cassette('legal_entity/name', vcr_options) do
          le = Opencrx::Model::LegalEntity.new(name: name)
          le = le.save
          expect(le.name).to eq(name)
        end
      end

      def query_for_name(name)
        options = {query: "thereExistsFullName().equalTo(\"#{name}\")"}
        Opencrx::Model::LegalEntity.query(options)
      end

      it "should find name" do
        VCR.use_cassette('legal_entity/find', vcr_options) do
          result_set = query_for_name(name)
          expect(result_set.length).to eq(1)
          le = result_set.first
          expect(le.name).to eq(name)
        end
      end

      it "should update name" do
        VCR.use_cassette('legal_entity/update', vcr_options) do
          le = query_for_name(name).first
          expect(le.name).to eq(name)
          new_name = 'AA More reasonable'
          le.name = new_name
          le = le.save
          expect(le.name).to eq(new_name)
        end
      end
    end

    context "addresses" do
      let(:name) { "AA With Address" }
      let(:legal_entity) { Opencrx::Model::LegalEntity.new(name: name).save }
      let(:address_hash) { {postalCity: 'Gütersloh', postalCode: '33330'} }

      it "should create with address" do
        VCR.use_cassette('legal_entity/address_create', vcr_options) do
          address = Opencrx::Model::PostalAddress.new(address_hash)
          address.assign_to(legal_entity)
          address = address.save
          expect(address.href).to match(legal_entity.href)
          expect(address.postalCity).to eq(address_hash[:postalCity])
          expect(address.postalCode).to eq(address_hash[:postalCode])
          addresses = legal_entity.addresses
          expect(addresses.length).to eq(1)
          expect(addresses.first.postalCode).to eq(address_hash[:postalCode])
        end
      end
    end

    context Opencrx::Model::Account do
      it "should query many accounts" do
        VCR.use_cassette('accounts', vcr_options) do
          result_set = Opencrx::Model::Account.query(size: 100)
          puts "#{result_set.length} accounts found"
          expect(result_set.length).to have_at_most(100).items
        end
      end
    end
  end
end
