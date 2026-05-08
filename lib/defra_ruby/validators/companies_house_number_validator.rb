# frozen_string_literal: true

module DefraRuby
  module Validators
    class CompaniesHouseNumberValidator < BaseValidator

      # Examples we need to validate are
      # 10997904, 09764739
      # SC534714, CE000958
      # IP00141R, IP27702R, SP02252R
      # https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/426891/uniformResourceIdentifiersCustomerGuide.pdf
      VALID_COMPANIES_HOUSE_REGISTRATION_NUMBER_REGEX =
        /\A(\d{8,8}$)|([a-zA-Z]{2}\d{6}$)|([a-zA-Z]{2}\d{5}[a-zA-Z]{1}$)\z/i

      def validate_each(record, attribute, value)
        return false unless value_is_present?(record, attribute, value)
        return false unless format_is_valid?(record, attribute, value)

        permitted_types = options[:permitted_types]
        permitted_statuses = options[:permitted_statuses]
        validate_with_companies_house(record, attribute, value, permitted_types, permitted_statuses)
      end

      private

      def value_is_present?(record, attribute, value)
        return true if value.present?

        add_validation_error(record, attribute, :blank)
        false
      end

      def format_is_valid?(record, attribute, value)
        # All-zero values are invalid, despite matching the main regex
        return true if value.match?(VALID_COMPANIES_HOUSE_REGISTRATION_NUMBER_REGEX) && !value.match(/^0+$/)

        add_validation_error(record, attribute, :invalid_format)
        false
      end

      def validate_with_companies_house(record, attribute, value, permitted_types, permitted_statuses)
        case CompaniesHouseService.new(company_number: value, permitted_types:, permitted_statuses:).status
        when :active
          true
        when :inactive
          add_validation_error(record, attribute, :inactive)
        when :not_found
          add_validation_error(record, attribute, :not_found)
        when :unsupported_company_type
          add_validation_error(record, attribute, :unsupported_company_type)
        else
          add_validation_error(record, attribute, :error)
        end
      rescue ArgumentError
        add_validation_error(record, attribute, :argument_error)
      rescue StandardError
        add_validation_error(record, attribute, :error)
      end
    end
  end
end
