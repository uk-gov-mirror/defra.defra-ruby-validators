# Defra Ruby Validators

![Build Status](https://github.com/DEFRA/defra-ruby-validators/workflows/CI/badge.svg?branch=main)
[![Maintainability Rating](https://sonarcloud.io/api/project_badges/measure?project=DEFRA_defra-ruby-validators&metric=sqale_rating)](https://sonarcloud.io/dashboard?id=DEFRA_defra-ruby-validators)
[![Coverage](https://sonarcloud.io/api/project_badges/measure?project=DEFRA_defra-ruby-validators&metric=coverage)](https://sonarcloud.io/dashboard?id=DEFRA_defra-ruby-validators)
[![Gem Version](https://badge.fury.io/rb/defra_ruby_validators.svg)](https://badge.fury.io/rb/defra_ruby_validators)
[![Licence](https://img.shields.io/badge/Licence-OGLv3-blue.svg)](http://www.nationalarchives.gov.uk/doc/open-government-licence/version/3)

Package of validations commonly used in Defra Rails based digital services.

## Installation

Add this line to your application's Gemfile

```ruby
gem "defra_ruby_validators"
```

And then update your dependencies by calling

```bash
bundle install
```

## Usage

With this gem installed, a number of active model based validators become available.

### Business type

This validator checks the value provided is one of our known business types

- `soleTrader`
- `limitedCompany`
- `partnership`
- `limitedLiabilityPartnership`
- `localAuthority`
- `charity`

If blank or not one of these it will return an error.

Add it to your model or form object using

```ruby
validates :business_type, "defra_ruby/validators/business_type": true
```

If you want to include `overseas` in the accepted business types, you can enable this in the options:

```ruby
validates :business_type, "defra_ruby/validators/business_type": { allow_overseas: true }
```

### Companies House number

This validator checks the company registration number provided. Specifically it first checks that it matches a known format. All registration numbers are 8 characters long but can be formatted in the following ways.

- 09764739
- 10997904
- SC534714
- IP00141R

If the format is valid, it then makes a call to Companies House to validate that the number

- is recognised
- belongs to a company with an allowed status

Allowed statuses default to `active` and `voluntary-arrangement`, preserving the existing behaviour.
Services can override this when they need to accept other Companies House statuses.

Add it to your model or form object using

```ruby
validates :company_no, "defra_ruby/validators/companies_house_number": true
```

The company number also accepts a `company_type` option. This checks the `type` attribute in the API response. To validate that the company number is for a Limited Company, for example:

```ruby
validates :company_no, "defra_ruby/validators/companies_house_number": { company_type: "ltd" }
```

The allowed Companies House statuses can be changed with the `permitted_statuses` option:

```ruby
validates :company_no, "defra_ruby/validators/companies_house_number": {
  permitted_statuses: %i[active voluntary-arrangement liquidation]
}
```

Note: to mock the Companies House service with the `company_type` option, you will need to be running at least v2.2.0 of [defra-ruby-mocks](https://github.com/DEFRA/defra-ruby-mocks#companies-house).

### Email

This validator checks the value is present and in a format that meets [RFC 2822](https://tools.ietf.org/html/rfc2822) and [RFC 3696](https://tools.ietf.org/html/rfc3696) (we use [validates_email_format_of](https://github.com/validates-email-format-of/validates_email_format_of) to check the format).

Add it to your model or form object using

```ruby
validates :email, "defra_ruby/validators/email": true
```

### Grid reference

This validator checks the value is present, is in the correct format for an [Ordnance Survey National Grid Reference](https://en.wikipedia.org/wiki/Ordnance_Survey_National_Grid), and that its valid (we use [os_map_ref](https://github.com/DEFRA/os-map-ref) to check the coordinate is valid).

Add it to your model or form object using

```ruby
validates :grid_reference, "defra_ruby/validators/grid_reference": true
```

### Location

This validator checks the value provided is one of our accepted locations

- `england`
- `northern_ireland`
- `scotland`
- `wales`

If blank or not one of these it will return an error.

Add it to your model or form object using

```ruby
validates :location, "defra_ruby/validators/location": true
```

If you want to include `overseas` in the accepted locations, you can enable this in the options:

 ```ruby
validates :location, "defra_ruby/validators/location": { allow_overseas: true }
```

### Past date

This validator checks the value provided is present and not a date in the future (`<= Date.today`).

Add it to your model or form object using

```ruby
validates :date_received, "defra_ruby/validators/past_date_validator": true
```

### Phone number

This validator checks the value is present, is not too long (15 is th maximum length for any phone number), and is in the correct format as per [E.164](https://en.wikipedia.org/wiki/E.164) (we use [phonelib](https://github.com/daddyz/phonelib) to check the format).

Add it to your model or form object using

```ruby
validates :phone_number, "defra_ruby/validators/phone_number": true
```

### Mobile phone number

This validator checks the value is present, is not too long (15 is th maximum length for any phone number), is a mobile phone number, and is in the correct format as per [E.164](https://en.wikipedia.org/wiki/E.164) (we use [phonelib](https://github.com/daddyz/phonelib) to check the format).

Add it to your model or form object using

```ruby
validates :mobile_phone_number, "defra_ruby/validators/mobile_phone_number": true
```

### Position

This validator checks the value provided for 'position' i.e. someones role or title within an organisation. This is an optional field so the validator has to handle the value being blank. If it's not then it can be no longer than 70 characters and only include letters, spaces, commas, full stops, hyphens and apostrophes else it will return an error.

Add it to your model or form object using

```ruby
validates :position, "defra_ruby/validators/position": true
```

### Token

This validator checks the value is present and in the correct format, which in this case is that the value has a length of 24. If blank or not in a valid format it will return an error.

Add it to your model or form object using

```ruby
validates :token, "defra_ruby/validators/token": true
```

### True or false

This validator checks the value provided is either `"true"` or `"false"`. If blank or not one of these it will return an error.

Add it to your model or form object using

```ruby
validates :is_a_farmer, "defra_ruby/validators/true_false": true
```

### Price

This validator checks the value is present and in the correct format, meaning it has no more than 2 decimal places. If blank or not in a valid format it will return an error.

Add it to your model or form object using

```ruby
validates :price, "defra_ruby/validators/price": true
```

## Adding custom error messages

All the validators in this gem have built-in error messages. But if you want, you can provide your own custom message in the app, like this:

```ruby
validates :position, "defra_ruby/validators/position": { messages: { too_long: "This position is too long" } }
```

You will need to know the error symbol raised by the validator (eg `too_long` or `invalid_format`).

## Contributing to this project

If you have an idea you'd like to contribute please log an issue.

All contributions should be submitted via a pull request.

## License

THIS INFORMATION IS LICENSED UNDER THE CONDITIONS OF THE OPEN GOVERNMENT LICENCE found at:

http://www.nationalarchives.gov.uk/doc/open-government-licence/version/3

The following attribution statement MUST be cited in your products and applications when using this information.

> Contains public sector information licensed under the Open Government license v3

### About the license

The Open Government Licence (OGL) was developed by the Controller of Her Majesty's Stationery Office (HMSO) to enable information providers in the public sector to license the use and re-use of their information under a common open licence.

It is designed to encourage use and re-use of information freely and flexibly, with only a few conditions.
