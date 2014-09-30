#------------------------------------------------------------------------------
#
# Organization
#
# Represents a basic organization in a flat organizational hierarchy
# without any relationships to other organizations or assets
#
#------------------------------------------------------------------------------
class Organization < ActiveRecord::Base
  
  #------------------------------------------------------------------------------
  # Callbacks
  #------------------------------------------------------------------------------
  after_initialize  :set_defaults

  # Enable automatic geocoding using the Geocoder gem
  geocoded_by       :full_address
  after_validation  :geocode  

  #------------------------------------------------------------------------------
  # Overrides
  #------------------------------------------------------------------------------
  #require rails to use the org short name as the restful parameter. All URLS will be of the form
  # /org/{short_name}/...
  def to_param
    short_name
  end

  #------------------------------------------------------------------------------
  # Associations common to all organizations
  #------------------------------------------------------------------------------

  # Every organization belongs to a customer
  belongs_to :customer

  # Every organization has a class type
  belongs_to :organization_type

  # Every organization can have a set of users
  has_many  :users
    
  # Every organization can have messages
  has_many  :messages

  # Every organization can have a set of uploads
  has_many  :uploads

  # Every organization can have 0 or more asset groups
  has_many  :asset_groups
          
  # Validations for associations  
  validates :customer_id,           :presence => true
  validates :organization_type_id,  :presence => true
  
  #------------------------------------------------------------------------------
  # Attributes common to all organization types
  #------------------------------------------------------------------------------
  # true if this organization holds the license for TransAM
  #attr_accessible :license_holder
  # names for the org. The short name must be unique
  #attr_accessible :name, :short_name
  # address and contact info
  #attr_accessible :address1, :address2, :city, :state, :zip, 
  #                :phone, :fax, :url 
  # other derived attributes                
  #attr_accessible :active
  
  # geocoded location for the organization
  #attr_accessible :latitude, :longitude  

  validates :name,                  :presence => true
  validates :short_name,            :presence => true, :uniqueness => true
  validates :address1,              :presence => true
  validates :city,                  :presence => true
  validates :state,                 :presence => true
  validates :zip,                   :presence => true
  #validates :license_holder, :presence => true
  validates :phone,                 :presence => true
  validates :url,                   :presence => true

  # List of allowable form param hash keys  
  FORM_PARAMS = [
    :customer_id,
    :organization_type_id,
    :external_id,
    :license_holder,
    :name,
    :short_name,
    :address1,
    :address2,
    :city,
    :state,
    :zip,
    :phone,
    :fax,
    :url,
    :active,
    :latitude,
    :longitude
  ]

  #------------------------------------------------------------------------------
  #
  # Class Methods
  #
  #------------------------------------------------------------------------------
      
  def self.allowable_params
    FORM_PARAMS
  end
      
  # returns a typed value of the organization if one exists
  def self.get_typed_organization(org)
    if org
      class_name = org.organization_type.class_name
      klass = Object.const_get class_name
      o = klass.find(org.id)
      return o
    end
  end
      
  #------------------------------------------------------------------------------
  #
  # Instance Methods
  #
  #------------------------------------------------------------------------------
        
  # Returns true if the organization is of the specified class or has the specified class as
  # and ancestor (superclass).
  #
  # usage: a.type_of? type
  # where type can be one of:
  #    a symbol e.g :grantee
  #    a class name eg Grantee
  #    a string eg "grantee"
  #
  def type_of?(type)
    begin
      self.class.ancestors.include?(type.to_s.classify.constantize)
    rescue
      false
    end
  end
        
  def coded_name
    "#{short_name}-#{name}"
  end      
  
  def object_key
    "#{id}"
  end
  
  def to_s
    short_name
  end
  
  # Generic organizations do not own transit assets
  def has_assets?
    false
  end   
            
  # Returns a policy for this org. This must be overriden for concrete classes
  def get_policy
    # get a typed version of the organization and return its value
    org = is_typed? ? self : Organization.get_typed_organization(self)
    return org.get_policy unless org.nil?    
  end
            
  # returns true if the organization instance is strongly typed, i.e., a concrete class
  # false otherwise.
  # true
  def is_typed?
    self.class.to_s == organization_type.class_name
  end
              
  def full_address
    elems = []
    elems << address1 unless address1.blank?
    elems << address2 unless address2.blank?
    elems << city unless city.blank?
    elems << state unless state.blank?
    elems << zip unless zip.blank?
    elems.compact.join(', ')    
  end
    
  #------------------------------------------------------------------------------
  #
  # Protected Methods
  #
  #------------------------------------------------------------------------------
  protected

  # Set resonable defaults for a new organization
  def set_defaults
    self.active ||= true
  end    
  
end
      
