# frozen_string_literal: true

require "spec_helper"
require "webmock/rspec"

module Test
  CompaniesHouseNumberValidatable = Struct.new(:company_no) do
    include ActiveModel::Validations

    validates :company_no, "defra_ruby/validators/companies_house_number": true
  end

  CompaniesHouseSinglePermittedTypeAndNumberValidatable = Struct.new(:company_no) do
    include ActiveModel::Validations

    validates :company_no, "defra_ruby/validators/companies_house_number": { permitted_types: "ltd" }
  end

  CompaniesHouseMultiplePermittedTypesAndNumberValidatable = Struct.new(:company_no) do
    include ActiveModel::Validations

    validates :company_no, "defra_ruby/validators/companies_house_number": { permitted_types: %w[llp ltd] }
  end

  CompaniesHousePermittedStatusesAndNumberValidatable = Struct.new(:company_no) do
    include ActiveModel::Validations

    validates :company_no, "defra_ruby/validators/companies_house_number": {
      permitted_statuses: %i[active voluntary-arrangement liquidation]
    }
  end

  CompaniesHouseInvalidPermittedTypesAndNumberValidatable = Struct.new(:company_no) do
    include ActiveModel::Validations

    # To align with the invalid_record shared_example
    messages = { argument_error: "something is wrong (in a customised way)" }

    validates :company_no, "defra_ruby/validators/companies_house_number": { permitted_types: { foo: :bar }, messages: }
  end
end

module DefraRuby
  module Validators
    RSpec.describe CompaniesHouseNumberValidator do

      let(:companies_house_service) { instance_double(CompaniesHouseService) }

      before do
        allow(CompaniesHouseService).to receive(:new).and_return(companies_house_service)
        allow(companies_house_service).to receive(:status)
      end

      valid_numbers = %w[10997904 09764739 SC534714 IP00141R]
      invalid_format_number = "foobar42"
      unknown_number = "99999999"
      inactive_number = "07281919"

      it_behaves_like "a validator"

      describe "#validate_each" do
        context "when given a valid company number" do
          before { allow(companies_house_service).to receive(:status).and_return(:active) }

          valid_numbers.each do |company_no|
            context "with #{company_no}" do
              it_behaves_like "a valid record", Test::CompaniesHouseNumberValidatable.new(company_no)
            end
          end
        end

        context "when given an invalid company number" do
          context "when it is blank" do
            validatable = Test::CompaniesHouseNumberValidatable.new
            error_message = Helpers::Translator.error_message(described_class, :blank)

            it_behaves_like "an invalid record",
                            validatable: validatable,
                            attribute: :company_no,
                            error: :blank,
                            error_message: error_message
          end

          context "when it is nil" do
            validatable = Test::CompaniesHouseNumberValidatable.new(nil)
            error_message = Helpers::Translator.error_message(described_class, :blank)

            it_behaves_like "an invalid record",
                            validatable: validatable,
                            attribute: :company_no,
                            error: :blank,
                            error_message: error_message
          end

          context "when the format is wrong" do
            validatable = Test::CompaniesHouseNumberValidatable.new(invalid_format_number)
            error_message = Helpers::Translator.error_message(described_class, :invalid_format)

            it_behaves_like "an invalid record",
                            validatable: validatable,
                            attribute: :company_no,
                            error: :invalid_format,
                            error_message: error_message
          end

          context "when it consists of all zeroes" do
            validatable = Test::CompaniesHouseNumberValidatable.new("00000000")
            error_message = Helpers::Translator.error_message(described_class, :invalid_format)

            it_behaves_like "an invalid record",
                            validatable: validatable,
                            attribute: :company_no,
                            error: :invalid_format,
                            error_message: error_message
          end

          context "when it's not found on companies house" do
            before { allow(companies_house_service).to receive(:status).and_return(:not_found) }

            validatable = Test::CompaniesHouseNumberValidatable.new(unknown_number)
            error_message = Helpers::Translator.error_message(described_class, :not_found)

            it_behaves_like "an invalid record",
                            validatable: validatable,
                            attribute: :company_no,
                            error: :not_found,
                            error_message: error_message
          end

          context "when it's not 'active' on companies house" do
            before { allow(companies_house_service).to receive(:status).and_return(:inactive) }

            validatable = Test::CompaniesHouseNumberValidatable.new(inactive_number)
            error_message = Helpers::Translator.error_message(described_class, :inactive)

            it_behaves_like "an invalid record",
                            validatable: validatable,
                            attribute: :company_no,
                            error: :inactive,
                            error_message: error_message
          end

          context "with a single permitted_types option" do
            it "calls the companies house service with the `ltd` param" do
              Test::CompaniesHouseSinglePermittedTypeAndNumberValidatable.new(valid_numbers.first).valid?

              expect(CompaniesHouseService).to have_received(:new)
                .with(company_number: valid_numbers.first, permitted_types: "ltd", permitted_statuses: nil)
            end
          end

          context "with multiple permitted_types options" do
            let(:permitted_types) { %w[llp ltd] }

            it "calls the companies house service with all permitted types" do
              Test::CompaniesHouseMultiplePermittedTypesAndNumberValidatable.new(valid_numbers.first).valid?

              expect(CompaniesHouseService).to have_received(:new)
                .with(company_number: valid_numbers.first, permitted_types:, permitted_statuses: nil)
            end
          end

          context "with multiple permitted_statuses options" do
            let(:permitted_statuses) { %i[active voluntary-arrangement liquidation] }

            it "calls the companies house service with all permitted statuses" do
              Test::CompaniesHousePermittedStatusesAndNumberValidatable.new(valid_numbers.first).valid?

              expect(CompaniesHouseService).to have_received(:new)
                .with(company_number: valid_numbers.first, permitted_types: nil, permitted_statuses:)
            end
          end

          context "with an invalid permitted_types option" do
            before do
              # Override the test instance double as we need to call a real instance for this spec:
              allow(CompaniesHouseService).to receive(:new).and_call_original

              stub_request(:any, %r{.*https://api.companieshouse.gov.uk/.*}).to_return(
                status: 200,
                body: { company_status: "active", type: "ltd" }.to_json
              )
            end

            validatable = Test::CompaniesHouseInvalidPermittedTypesAndNumberValidatable.new(valid_numbers.first)
            error_message = "something is wrong (in a customised way)"

            it_behaves_like "an invalid record",
                            validatable: validatable,
                            attribute: :company_no,
                            error: :argument_error,
                            error_message: error_message
          end
        end

        context "when there is an error connecting with companies house" do
          before { allow(companies_house_service).to receive(:status).and_raise(StandardError) }

          validatable = Test::CompaniesHouseNumberValidatable.new(valid_numbers.sample)
          error_message = Helpers::Translator.error_message(described_class, :error)

          it_behaves_like "an invalid record",
                          validatable: validatable,
                          attribute: :company_no,
                          error: :error,
                          error_message: error_message
        end
      end
    end
  end
end
