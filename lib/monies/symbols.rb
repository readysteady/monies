# frozen_string_literal: true

class Monies::Symbols
  def initialize
    @hash, @inverse_hash = Hash.new, Hash.new
  end

  def keys
    @keys ||= Regexp.new(@hash.keys.map { Regexp.escape(_1) }.join('|'))
  end

  def values
    @values ||= Regexp.new(@hash.values.map { Regexp.escape(_1) }.join('|'))
  end

  def fetch(key)
    @hash.fetch(key)
  end
  alias_method :[], :fetch

  def fetch_key(value)
    @inverse_hash.fetch(value)
  end

  def store(key, value)
    @hash[key] = value

    @inverse_hash[value] = key

    @keys, @values = nil

    value
  end
  alias_method :[]=, :store

  def update(hash)
    @hash.update(hash)

    @inverse_hash = @hash.invert

    @keys, @values = nil

    self
  end
end
