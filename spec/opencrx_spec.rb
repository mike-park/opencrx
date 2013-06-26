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

    context "create, find, update & delete" do
      let(:name) { "AA äöëïöü" }
      let(:legal_entity) { Opencrx::Model::LegalEntity.new(name: name) }

      def query_for_name(name)
        options = {query: "thereExistsFullName().equalTo(\"#{name}\")"}
        Opencrx::Model::LegalEntity.query(options)
      end

      it "should create with umlauts" do
        VCR.use_cassette('legal_entity/name', vcr_options) do
          expect(legal_entity.identity).to_not be

          expect(legal_entity.save).to eq(true)
          expect(legal_entity.name).to eq(name)
          expect(legal_entity.identity).to be
          legal_entity.destroy
        end
      end

      it "should delete name" do
        VCR.use_cassette('legal_entity/delete', vcr_options) do
          expect(legal_entity.save).to eq(true)
          expect(legal_entity.destroy).to eq(true)
          expect {Opencrx::Model::LegalEntity.get(legal_entity.href)}.to raise_error(Opencrx::HttpError, /404 Not Found/)
        end
      end

      it "should find name" do
        VCR.use_cassette('legal_entity/find', vcr_options) do
          result_set = query_for_name(name)
          result_set.each(&:destroy)

          legal_entity.save
          result_set = query_for_name(name)
          expect(result_set.length).to eq(1)
          le = result_set.first
          expect(le.name).to eq(name)
          le.destroy
        end
      end

      it "should update name" do
        VCR.use_cassette('legal_entity/update', vcr_options) do
          legal_entity.save
          expect(legal_entity.name).to eq(name)
          original_modifiedAt = legal_entity.modifiedAt
          new_name = 'AA More reasonable'
          legal_entity.name = new_name
          expect(legal_entity.save).to eq(true)
          expect(legal_entity.name).to eq(new_name)
          expect(legal_entity.modifiedAt).to_not eq(original_modifiedAt)
          legal_entity.destroy
        end
      end
    end

    context "addresses" do
      let(:name) { "AA With Address" }
      let(:legal_entity) { Opencrx::Model::LegalEntity.new(name: name) }
      let(:address_hash) { {postalCity: 'Gütersloh', postalCode: '33330'} }

      it "should create with address" do
        VCR.use_cassette('legal_entity/address_create', vcr_options) do
          expect(legal_entity.save).to eq(true)
          address = Opencrx::Model::PostalAddress.new(address_hash)
          address.assign_to(legal_entity)
          expect(address.save).to eq(true)
          expect(address.href).to match(legal_entity.href)
          expect(address.postalCity).to eq(address_hash[:postalCity])
          expect(address.postalCode).to eq(address_hash[:postalCode])
          addresses = legal_entity.addresses
          expect(addresses.length).to eq(1)
          expect(addresses.first.postalCode).to eq(address_hash[:postalCode])
          legal_entity.destroy
        end
      end
    end

    context Opencrx::Model::Account do
      it "should query many accounts" do
        VCR.use_cassette('accounts/10', vcr_options) do
          result_set = Opencrx::Model::Account.query(size: 10)
          puts "#{result_set.length} accounts found"
          expect(result_set.length).to have_at_most(10).items
        end
      end

      it "should query all accounts" do
        VCR.use_cassette('accounts/all', vcr_options) do
          #Opencrx::logger.level = Logger::DEBUG
          position = 0
          size = 500
          total = 0
          begin
            result_set = Opencrx::Model::Account.query(position: position, size: size)
            total += result_set.length
            position += size
            puts "#{position}: #{result_set.length}: #{total}"
          end while result_set.more?
          puts "#{total} accounts"
          expect(total).to have_at_least(1).items
        end
      end
    end
  end
end
