# frozen_string_literal: true

require "defra_ruby/companies_house"

module DefraRuby
  module Validators
    class CompaniesHouseService
      DEFAULT_PERMITTED_STATUSES = %i[active voluntary-arrangement].freeze
      ARGUMENT_ERROR_TRANSLATION_KEY = "defra_ruby.validators.CompaniesHouseNumberValidator.argument_error"

      private_constant :ARGUMENT_ERROR_TRANSLATION_KEY

      def initialize(company_number:, permitted_types: nil, permitted_statuses: nil)
        @company_number = company_number
        @permitted_types = permitted_types
        @permitted_statuses = permitted_statuses

        validate_permitted_types
        validate_permitted_statuses
      end

      def status
        return :unsupported_company_type unless company_type_is_allowed?(companies_house_response)

        status_is_allowed?(companies_house_response) ? :active : :inactive
      rescue DefraRuby::CompaniesHouse::CompanyNotFoundError
        :not_found
      end

      private

      def companies_house_response
        @companies_house_response ||= DefraRuby::CompaniesHouse::API.run(company_number: @company_number)
      end

      def validate_permitted_types
        return if valid_permitted_option?(@permitted_types)

        raise ArgumentError, I18n.t(ARGUMENT_ERROR_TRANSLATION_KEY)
      end

      def validate_permitted_statuses
        return if valid_permitted_option?(@permitted_statuses)

        raise ArgumentError, I18n.t(ARGUMENT_ERROR_TRANSLATION_KEY)
      end

      def valid_permitted_option?(option)
        option.nil? || option.is_a?(String) || option.is_a?(Array)
      end

      def status_is_allowed?(companies_house_response)
        normalised_permitted_statuses.include?(companies_house_response[:company_status].to_s.to_sym)
      end

      def normalised_permitted_statuses
        @permitted_statuses ||= DEFAULT_PERMITTED_STATUSES
        Array(@permitted_statuses).map { |status| status.to_s.to_sym }
      end

      def company_type_is_allowed?(companies_house_response)
        # if permitted_types has not been defined in the validator, we skip this check
        return true if @permitted_types.blank?

        case @permitted_types
        when String
          @permitted_types == companies_house_response[:company_type].to_s
        when Array
          @permitted_types.include?(companies_house_response[:company_type].to_s)
        else
          raise ArgumentError, I18n.t(ARGUMENT_ERROR_TRANSLATION_KEY)
        end
      end
    end
  end
end
