class Field < ActiveRecord::Base
  acts_as_list

  serialize :collection, Array

  belongs_to :field_group

  delegate :klass, :klass_name, :klass_name=, :to => :field_group

  KLASSES = [Task, Campaign, Lead, Contact, Account, Opportunity]

  FIELD_TYPES = {
    'string'      => :string,
    'text'        => :text,
    'email'       => :string,
    'url'         => :string,
    'tel'         => :string,
    'select'      => :string,
    'radio'       => :string,
    'check_boxes' => :text,
    'boolean'     => :boolean,
    'date'        => :date,
    'datetime'    => :timestamp,
    'decimal'     => [:decimal, {:precision => 15, :scale => 2}],
    'integer'     => :integer,
    'float'       => :float
  }

  validates_presence_of :label, :message => "^Please enter a Field label."
  validates_length_of :label, :maximum => 64, :message => "^The Field name must be less than 64 characters in length."

  validates_numericality_of :maxlength, :only_integer => true, :allow_blank => true, :message => "^Max size can only be whole number."

  validates_presence_of :as, :message => "^Please specify a Field type."
  validates_inclusion_of :as, :in => FIELD_TYPES.keys, :message => "Invalid Field Type."


  def self.field_types
    # Expands concise FIELD_TYPES into a more usable hash
    @field_types ||= FIELD_TYPES.inject({}) do |hash, n|
      arr = [n[1]].flatten
      hash[n[0]] = {:type => arr[0], :options => arr[1]}
      hash
    end
  end

  def column_type(field_type = self.as)
    (opts = Field.field_types[field_type]) ? opts[:type] : raise("Unknown field_type: #{field_type}")
  end

  def input_options
    input_html = {:maxlength => attributes[:maxlength]}

    attributes.select { |k,v|
      %w(as collection disabled label placeholder required).include?(k)
    }.symbolize_keys.merge(:input_html => input_html)
  end

  def collection_string=(value)
    self.collection = value.split("|").map(&:strip).reject(&:blank?)
  end
  def collection_string
    collection.try(:join, "|")
  end
end

