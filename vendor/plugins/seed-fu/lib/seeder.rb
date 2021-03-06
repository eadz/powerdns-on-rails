class Seeder
  def self.plant(model_class, *constraints, &block)
    constraints = [:id] if constraints.empty?
    seed = Seeder.new(model_class)
    seed.set_constraints(*constraints)
    yield seed
    seed.plant!
  end
  
  def initialize(model_class)
    @model_class = model_class
    @constraints = [:id]
    @data = {}
  end
  
  def set_constraints(*constraints)
    raise "You must set at least one constraint." if constraints.empty?
    @constraints = []
    constraints.each do |constraint|
      raise "Your constraint `#{constraint}` is not a column in #{@model_class}. Valid columns are `#{@model_class.column_names.join("`, `")}`." unless @model_class.column_names.include?(constraint.to_s)
      @constraints << constraint.to_sym
    end
  end
  
  def set_attribute(name, value)
    @data[name.to_sym] = value
  end
  
  def plant!
    record = get
    @data.each do |k, v|
      record.send("#{k}=", v)
    end
    record.save!
    puts " - #{@model_class} #{condition_hash.inspect}"
    record
  end
  
  def method_missing(method_name, *args) #:nodoc:
    if (match = method_name.to_s.match(/(.*)=$/)) && args.size == 1
      set_attribute(match[1], args.first)
    else
      super
    end
  end
  
  protected
  
  def get
    records = @model_class.find(:all, :conditions => condition_hash)
    raise "Given constraints yielded multiple records." unless records.size < 2
    if records.any?
      return records.first
    else
      return @model_class.new
    end
  end
  
  def condition_hash
    @data.reject{|a,v| !@constraints.include?(a)}
  end
end

class ActiveRecord::Base
  # Creates a single record of seed data for use
  # with the db:seed rake task. 
  # 
  # === Parameters
  # constraints :: Immutable reference attributes. Defaults to :id
  def self.seed(*constraints, &block)
    Seeder.plant(self, *constraints, &block)
  end
end