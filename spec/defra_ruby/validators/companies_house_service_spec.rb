# frozen_string_literal: true

require "webmock/rspec"

RSpec.describe DefraRuby::Validators::CompaniesHouseService do
  let(:host) { "https://api.companieshouse.gov.uk/" }

  describe "#status" do
    subject(:companies_house_service) { described_class.new(company_number:) }

    let(:defra_ruby_companies_house) { instance_double(DefraRuby::CompaniesHouse::API) }
    let(:company_number) { "09360070" }
    let(:company_type) { :ltd }
    let(:company_status) { :active }

    before do
      allow(DefraRuby::CompaniesHouse::API).to receive(:new).and_return(defra_ruby_companies_house)
      allow(defra_ruby_companies_house).to receive(:run)
        .and_return({ company_name: "Acme", company_status:, company_type: })
    end

    context "when the company_number is for an active company" do
      let(:company_status) { :active }

      context "with an eight-digit company_number" do
        let(:company_number) { "19360070" }

        it "returns :active" do
          expect(companies_house_service.status).to eq(:active)
        end
      end

      context "with a seven-digit company_number with a leading zero" do
        let(:company_number) { "09360070" }

        it "returns :active" do
          expect(companies_house_service.status).to eq(:active)
        end
      end

      context "with a seven-digit company_number without a leading zero" do
        let(:company_number) { "9360070" }

        it "returns :active" do
          expect(companies_house_service.status).to eq(:active)
        end
      end
    end

    context "when the company_number is not found" do
      before do
        allow(defra_ruby_companies_house).to receive(:run)
          .and_raise(DefraRuby::CompaniesHouse::CompanyNotFoundError.new(company_number:))
      end

      it "returns :not_found" do
        expect(companies_house_service.status).to eq(:not_found)
      end
    end

    context "when the company_number is inactive" do
      let(:company_status) { :dissolved }

      it "returns :inactive" do
        expect(companies_house_service.status).to eq(:inactive)
      end
    end

    context "when the company_number has a liquidation status" do
      let(:company_status) { :liquidation }

      it "returns :inactive by default" do
        expect(companies_house_service.status).to eq(:inactive)
      end
    end

    context "when checking the company_status" do
      subject(:companies_house_service) { described_class.new(company_number: "09360070", permitted_statuses:) }

      context "when an invalid permitted company statuses value is specified" do
        let(:permitted_statuses) { 0 }

        it { expect { companies_house_service.status }.to raise_error(ArgumentError) }
      end

      context "when a single permitted company status is specified" do
        let(:permitted_statuses) { "liquidation" }
        let(:company_status) { :liquidation }

        it { expect(companies_house_service.status).to eq(:active) }
      end

      context "when multiple permitted company statuses are specified" do
        let(:permitted_statuses) { %i[active voluntary-arrangement liquidation] }

        context "when the actual status is liquidation" do
          let(:company_status) { :liquidation }

          it { expect(companies_house_service.status).to eq(:active) }
        end

        context "when the actual status is dissolved" do
          let(:company_status) { :dissolved }

          it { expect(companies_house_service.status).to eq(:inactive) }
        end
      end
    end

    context "when checking the company_type" do
      subject(:companies_house_service) { described_class.new(company_number: "09360070", permitted_types:) }

      context "when an invalid permitted company types value is specified" do
        let(:permitted_types) { 0 }
        let(:company_type) { nil }

        it { expect { companies_house_service.status }.to raise_error(ArgumentError) }
      end

      context "when no permitted company types are specified" do
        let(:permitted_types) { nil }
        let(:company_type) { nil }

        it { expect(companies_house_service.status).to eq(:active) }
      end

      context "when a single permitted company type is specified" do
        let(:permitted_types) { "ltd" }

        context "when the actual type is llp" do
          let(:company_type) { :llp }

          it { expect(companies_house_service.status).to eq(:unsupported_company_type) }
        end

        context "when the actual type is ltd" do
          let(:company_type) { :ltd }

          it { expect(companies_house_service.status).to eq(:active) }
        end
      end

      context "when multiple permitted company types are specified" do
        let(:permitted_types) { %w[ltd llp] }

        context "when the actual type is llp" do
          let(:company_type) { :llp }

          it { expect(companies_house_service.status).to eq(:active) }
        end

        context "when the actual type is ltd" do
          let(:company_type) { :ltd }

          it { expect(companies_house_service.status).to eq(:active) }
        end
      end
    end

    context "when there is a problem with the Companies House API" do
      context "when the request times out" do
        before { allow(defra_ruby_companies_house).to receive(:run).and_raise(DefraRuby::CompaniesHouse::ApiTimeoutError) }

        it "raises an exception" do
          expect { companies_house_service.status }.to raise_error(StandardError)
        end
      end

      context "when the request returns an error" do
        before { allow(defra_ruby_companies_house).to receive(:run).and_raise(SocketError) }

        it "raises an exception" do
          expect { companies_house_service.status }.to raise_error(StandardError)
        end
      end
    end
  end
end
