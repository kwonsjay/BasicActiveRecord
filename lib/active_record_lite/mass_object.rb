class MassObject
  def self.my_attr_accessible(*attributes)
    @attributes = attributes
    attributes.each do |attribute|
      self.send(:attr_accessor, attribute)
    end
  end

  def self.attributes
    @attributes
  end

  def self.parse_all(results)
    results.map { |result| self.new(result) }
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      if self.class.attributes.include?(attr_name.to_sym)
        self.send("#{attr_name}=", value)
      else
        raise "mass assignment to unregistered attribute #{attr_name}"
      end
    end
  end
end