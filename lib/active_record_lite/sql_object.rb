require_relative './associatable'
require_relative './db_connection'
require_relative './mass_object'
require_relative './searchable'
require 'active_support/inflector'

class SQLObject < MassObject
  extend Searchable
  extend Associatable
  def self.set_table_name(table_name)
    @table_name = table_name.underscore.pluralize
  end

  def self.table_name
    @table_name
  end

  def self.all
    results = DBConnection.execute("SELECT * FROM #{@table_name}")
    results.map { |result| SQLObject.new(result) }
  end

  def self.find(id)
    results = DBConnection.execute(<<-SQL, id)
    SELECT
      *
    FROM
      #{self.table_name}
    WHERE
      id = ?
    SQL
    self.new(results.first)
  end

  def create
    DBConnection.execute(<<-SQL, *attribute_values)
    INSERT INTO
      "#{self.table_name} #{self.attributes.join(', ')}"
    VALUES
      #{ ['?'] * self.class.attributes.count }
    SQL
    @id = DBConnection.last_insert_row_id
  end

  def update
    DBConnection.execute(<<-SQL, *attribute_values)
    UPDATE
      #{self.class.table_name}
    SET
      #{self.class.attributes.map { |attribute| "#{attribute} = ?" }.join(', ')}
    WHERE
      id = #{@id}
    SQL
  end

  def save
    if self.id.nil?
      create
    else
      update
    end
  end

  def attribute_values
    self.class.attributes.map { |attribute| send(attribute.to_sym) }
  end
end
