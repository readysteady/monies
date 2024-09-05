# monies

Ruby gem for representing monetary values.

Pure Ruby—compatible with MRI/CRuby, JRuby, TruffleRuby, and Natalie.


## Installation

Using Bundler:

    $ bundle add monies

Using RubyGems:

    $ gem install monies


## Usage

Getting started:

```ruby
require 'monies'

a = Monies(11, 'USD')
b = Monies('22.22', 'USD') * 2
c = Monies.parse('$33.44')

puts Monies.format(a + b + c, symbol: true)
```


## Currencies

Currencies are represented as strings. Using [ISO 4217 currency codes](https://en.wikipedia.org/wiki/ISO_4217)
is recommended for maximum interoperability, however there are no restrictions
on what strings you can use. For example:

```ruby
Monies(10, 'USD')
Monies(10, 'BTC')
Monies(10, 'GBX')
Monies(10, 'X')
Monies(10, 'LOL')
Monies(10, 'Cubit')
Monies(10, 'Latinum')
Monies(10, 'sats')
```

If your application primarily uses a single currency you can set a default currency:

```ruby
Monies.currency = 'USD'

Monies(10)
```


## Arithmetic

Arithmetic is currency checked to prevent errors:

```ruby
Monies(1, 'USD') + Monies(1, 'RUB')  # raises Monies::CurrencyError
```

If you need to sum amounts in different currencies you should first convert
them all to the same currency.

Division is limited to 16 decimal places by default, which ought to be enough
for everyone. If you need more accuracy you can use the #div method to specify
the maximum number of decimal places you want:

```ruby
Monies(1, 'USD').div(9, 100)
```


## Currency conversion

Use the #convert method to convert instances to another currency:

```ruby
value = Monies('1.23', 'BTC')

price = Monies(100_000, 'USD')

puts value.convert(price).round(2)
```

Fetching price data, caching that data, and rounding the result are all
responsibilities of the caller.


## Parsing strings

Use the `Monies` method to convert strings that are expected to be valid and
don't contain special formatting, such as those in source code and databases:

```ruby
Monies('12345.6')
```

Use the `Monies.parse` method to parse strings that could be invalid or could
contain special formatting like thousand separators, currency codes, or symbols:

```ruby
Monies.parse('£1,999.99')
Monies.parse('1.999,00 EUR')
```

An `ArgumentError` exception is raised for invalid input:

```ruby
Monies.parse('notmoney')  # raises ArgumentError
```

Currency symbols and currency codes are defined in `Monies.symbols` which can
be updated to support additional currencies using #[]= or #update. For example:

```ruby
Monies.symbols["\u20BF"] = 'BTC'

Monies.symbols.update({"\u20BF" => 'BTC'})

Monies.parse('1,000 BTC')
```


## Formatting strings

Use the `Monies.format` method to produce formatted strings:

```ruby
Monies.format(Monies('1234.56', 'USD'))  # "1,234.56"
```

Specify the `code` or `symbol` options to include the currency code or symbol:

```ruby
Monies.format(Monies('1234.56', 'USD'), code: true)  # "1,234.56 USD"

Monies.format(Monies('1234.56', 'USD'), symbol: true)  # "$1,234.56"
```

Specify the name of the format to use different formatting rules:

```ruby
Monies.format(Monies('1234.56', 'USD'), :eu)  # "1.234,56"
```

The default format is `:en` and can be changed by updating `Monies.formats`,
for example to change the default format to the built-in `:eu` format:

```ruby
Monies.formats[:default] = Monies.formats[:eu]
```

To create a custom format first create a `Monies::Format` subclass,
and then add the format to `Monies.formats`. For example:

```ruby
class CustomFormat < Monies::Format::EN
  # ...
end

Monies.formats[:custom] = CustomFormat.new
```


## BigDecimal integration

Monies integrates with the [bigdecimal gem](https://rubygems.org/gems/bigdecimal)
for multiplication and currency conversion. For example:

```ruby
require 'bigdecimal/util'

Monies('1.23', 'USD') * BigDecimal('0.1')
```

Use the `Monies` method to convert from a `BigDecimal` value:

```ruby
Monies(BigDecimal(10), 'USD')
```

Use the #to_d method to convert to a `BigDecimal` value:

```ruby
monies.to_d
```

Specify a currency argument to use `BigDecimal` values for currency conversion:

```ruby
monies = Monies('1.11', 'BTC')
monies.convert(BigDecimal(100_000), 'USD').round(2)
```


## Percentage integration

Monies integrates with the [percentage gem](https://rubygems.org/gems/percentage)
for percentage calculations. For example:

```ruby
require 'percentage'

capital_gains = Monies(10_000, 'GBP')

tax_rate = Percentage.new(20)

tax_liability = capital_gains * tax_rate

puts tax_liability
```


## Sequel integration

Monies integrates with the [sequel gem](https://rubygems.org/gems/sequel)
to support database serialization. For example:

```ruby
class Product < Sequel::Model
  plugin Monies::Serialization::Sequel

  serialize_monies :price
end
```

This will serialize the value and the currency as a single string.

You can also specify the currency at the model/application level using the
currency keyword argument:

```ruby
serialize_monies :price, currency: Monies.currency
```

This will serialize just the value as a single string.

You can also use two columns, one for the value and an additional string column
to store the currency:

```ruby
serialize_monies :price, currency: :currency
```

## ActiveRecord integration

Monies integrates with the [activerecord gem](https://rubygems.org/gems/activerecord)
to support database serialization. For example:

```ruby
class Product < ApplicationRecord
  include Monies::Serialization::ActiveRecord

  serialize_monies :price
end
```

Usage of `serialize_monies` is identical to the [sequel integration](#sequel-integration).


## License

Monies is released under the LGPL-3.0 license.
