require 'active_support/core_ext/object/try'
require 'active_support/inflector'
require_relative './db_connection.rb'

class AssocParams
  attr_reader :other_class_name, :primary_key, :foreign_key
  def other_class
    other_class_name.constantize
  end

  def other_table
    other_class.table_name
  end
end

class BelongsToAssocParams < AssocParams
  def initialize(name, params)
    @other_class_name = params[:other_class_name]  || name.to_s.camelcase
    @primary_key      = params[:primary_key] || 'id'
    @foreign_key      = params[:foreign_key] || "#{name}_id"
  end
end

class HasManyAssocParams < AssocParams
  def initialize(name, params, self_class)
    @other_class_name = params[:other_class_name]  || name.to_s.singularize.camelcase
    @primary_key      = params[:primary_key] || 'id'
    @foreign_key      = params[:foreign_key] || "#{self_class.name.underscore}_id"
  end
end

module Associatable
  def assoc_params
  end

  def belongs_to(name, params = {})
    owner = BelongsToAssocParams.new(name, params)
    define_method(name.to_s) do
      intermediate = send(owner.foreign_key)
      results = DBConnection.execute(<<-SQL, intermediate)
      SELECT
        *
      FROM
        #{owner.other_table}
      WHERE
        id = ?
      SQL
      owner.other_class.parse_all(results).first
    end
  end

  def has_many(name, params = {})
    minion = HasManyAssocParams.new(name, params, self)
    define_method(name.to_s) do
      intermediate = send(minion.primary_key)
      results = DBConnection.execute(<<-SQL, intermediate)
      SELECT
        *
      FROM
        #{minion.other_table}
      WHERE
        #{minion.foreign_key} = ?
      SQL
      minion.other_class.parse_all(results)
    end
  end

  def has_one_through(name, assoc1, assoc2)
    define_method(name.to_s) do
      send(assoc1).send(assoc2)
    end
  end
end
