# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)

# Maintain your gem"s version:
require "defra_ruby/validators/version"

Gem::Specification.new do |spec|
  spec.name          = "defra_ruby_validators"
  spec.version       = DefraRuby::Validators::VERSION
  spec.authors       = ["Defra"]
  spec.email         = ["alan.cruikshanks@environment-agency.gov.uk"]
  spec.license       = "The Open Government Licence (OGL) Version 3"
  spec.homepage      = "https://github.com/DEFRA/defra-ruby-validators"
  spec.summary       = "Defra ruby on rails validations"
  spec.description   = "Package of validations commonly used in Defra Rails based digital services"
  spec.required_ruby_version = ">= 3.2"

  spec.files = Dir["{bin,config,lib}/**/*", "LICENSE", "Rakefile", "README.md"]

  spec.require_paths = ["lib"]

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
          "public gem pushes."
  end

  # Include ActiveModel so that we have access to ActiveModel::Validations
  # ActiveModel::Validation is the central class within gem!
  spec.add_dependency "activemodel"

  # Use the companies house gem to retrieve information from the Companies House REST API
  spec.add_dependency "defra_ruby_companies_house"

  spec.add_dependency "i18n"
  spec.add_dependency "matrix"
  # Used to validate national grid references
  spec.add_dependency "os_map_ref"
  # Use to ensure phone numbers are in a valid and recognised format
  spec.add_dependency "phonelib"
  # Use rest-client for external requests, eg. to Companies House
  spec.add_dependency "rest-client", "~> 2.0"
  # Used to validate UK postcodes
  spec.add_dependency "uk_postcode"
  # Use to validate e-mail addresses against RFC 2822 and RFC 3696
  spec.add_dependency "validates_email_format_of"
  spec.metadata["rubygems_mfa_required"] = "true"
end
