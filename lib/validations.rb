require 'json'
require File.expand_path('exceptions', File.dirname(__FILE__))

module Trd
  class Validations

    def self.validate_params(params, required, optional)

      # todo(siddarth): the error messages are reasonably fine-grained
      # and helpful, but do we want to go all out and make them very
      # specific?

      # Convert all the strings to symbols
      params = params.inject({}){ |memo, (k,v) | memo[k.to_sym] = v; memo}

      keys = required.keys + optional.keys

      # Make sure all required parameters are specified,
      # and their types are correct.
      required.each do |key, type|
        val = params[key]
        raise TrdError.new("Missing required field '#{key.to_s}'") if val.nil?
        raise TrdError.new("Field '#{key.to_s}' should be of type #{type.to_s}") unless is_of_type(val, type)
      end

      # Check types for any optional parameters.
      optional.each do |key, type|
        val = params[key]
        next if val.nil?
        raise TrdError.new("Field '#{key.to_s}' should be of type #{type.to_s}") unless is_of_type(val, type)
      end

      # Make sure nothing else is passed on.
      params.each do |key, val|
        raise TrdError.new("Unknown field '#{key.to_s}' specified") unless keys.include? key
      end
    end

    private

    # true if val is of type `type`, false otherwise.
    # Presumes all `val`s that are passed are Strings by default.
    # todo(siddarth): currently supports String, and Integer. More?
    def self.is_of_type(val, type)
      if type == String
        return true
      elsif type == Integer
        return true if val =~ /^\d+$/
      else
        return false
      end
    end
  end
end