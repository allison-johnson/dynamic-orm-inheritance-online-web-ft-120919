require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord

  #Returns a table name based on the class name
  def self.table_name
    self.to_s.downcase.pluralize
  end

  #Returns table's column names in an arry
  def self.column_names
    DB[:conn].results_as_hash = true

    sql = "pragma table_info('#{table_name}')"

    table_info = DB[:conn].execute(sql) 
    #table_info is an array of hashes

    column_names = []
    table_info.each do |row|
      #Picks of the value associated with the "name" key for each row hash
      column_names << row["name"]
    end
    #Removes any 'nil' values from the array before returning it
    column_names.compact
  end

  def initialize(options={})
    options.each do |property, value|
      #Calls the setter method for each property and assigns it to 'value'
      self.send("#{property}=", value)
    end
  end

  def save
    #Creates SQL code that says what table to insert into, which columns, and what values should be inserted
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    DB[:conn].execute(sql)

    #Sets the @id attribute of self to the id from the table
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def table_name_for_insert
    #Since table_name is a class method, this allows instances to find the table name so they can 'save' themselves
    self.class.table_name
  end

  def values_for_insert
    values = []
    #Iterates over each column name in the array of column names
    self.class.column_names.each do |col_name|
      #col_name is a getter method, so doesn't take any parameters
      #Whatever col_name returns (i.e., the value of that attribute) gets shoveled onto 'values'
      #But first, the value of that attribute gets enclosed in single quotes, the way SQL wants it
      #Finally, if that attribute is nil, don't shovel it onto values
      values << "'#{send(col_name)}'" unless send(col_name).nil?
    end
    #Change value from an array into a comma-separated string
    values.join(", ")
  end

  def col_names_for_insert
    #Since column_names is a class method, self.class.column_names allows an instance to call it
    #We are then going to delete the column name of "id"
    #Finally, we turn the column names from an array into string, into a single comma-separated string
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
  end

def self.find_by_name(name)
  #Returns an array of hashes, each hash representing a row in the table where the name matches the specified 'name'
  sql = "SELECT * FROM #{self.table_name} WHERE name = ?"
  DB[:conn].execute(sql, name)
end

end
