require_relative './db_connection'

module Searchable
  def where(params)
    keys = params.keys.map { |key| "#{key} = ?" }.join(' AND ')
    values = params.values
    results = DBConnection.execute(<<-SQL, values)
    SELECT
      *
    FROM
      #{self.table_name}
    WHERE
      #{keys}
    SQL
    [].tap do |obj_arr|
      results.each do |result|
        obj_arr << self.new(result)
      end
    end
  end
end