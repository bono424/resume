require 'data_mapper'
require 'digest/sha2'

# Just log to STDOUT for now.
DataMapper::Logger.new($stdout, :debug)

include Trd

# todo(siddarth): make sure that DM can be easily migrated
# to mongo or SQL without major changes.
if (ENV["RACK_ENV"] == "production")
  DataMapper.setup( :default, "sqlite3://#{Dir.pwd}/trd.db" )
else
  DataMapper.setup( :default, "sqlite3://#{Dir.pwd}/trd.test.db" )
end

DataMapper::Model.raise_on_save_failure = true

class User
  include DataMapper::Resource
  property :id, Serial, :key => true
  property :email, String
  property :password, String, :length => 256
  property :salt, String
  property :verification_key, String
  property :is_verified, Boolean, :default => false
  property :type, Discriminator
end

class Student < User
  property :name,             String
  property :secondary_email,  String
  property :birthday,         Date
  property :school,           String
  property :major,            String
  property :minor,            String
  property :gpa,              Float
  property :gender,           String
  property :interest1,        String
  property :interest2,        String
  property :interest3,        String
  property :class,            Integer
  property :photo,            String
  property :resume,           String
  property :has_done_stages, Boolean, :default => false
  property :is_employer, Boolean, :default => false

  has n, :experiences
  has n, :extracurriculars
end

class Employer < User
  property :is_employer, Boolean, :default => true
  property :email,        String
  property :name,         String
  property :handle,       String
  property :url,          String
  property :founded,      Integer
  property :description,  String, :length => 1024
  property :handle,       String
  property :address,      String
  property :city,        String
  property :state,        String
  property :zipcode,      String
  property :photo,        String
  property :phone,        String

  has n, :postings
end

class Experience
  include DataMapper::Resource

  belongs_to :student

  property :id,               Serial, :key => true
  property :position,         String
  property :place,            String
  property :desc,            String, :length => 1024
  property :start_date,       Date
  property :end_date,         Date
end

class Extracurricular
  include DataMapper::Resource

  belongs_to :student

  property :id,               Serial, :key => true
  property :position,         String
  property :place,            String
  property :desc,            String, :length => 1024
  property :start_date,       Date
  property :end_date,         Date
end

class Posting
  include DataMapper::Resource

  belongs_to :employer

  property :id,             Serial, :key => true
  property :position,       String
  property :place,          String
  property :description,    String
  property :start_date,     Date
  property :end_date,       Date
  property :deadline,       Date
  property :class,          String
  property :qualifications, String
  property :contact_name,   String
  property :contact_email,  String
end

class Subscription
  include DataMapper::Resource

  property :id, Serial
  property :charge_id, String
  property :employer_id, Integer
  property :is_processed, Boolean, :default => false
  property :is_recurring, Boolean, :default => false
end

# Create tables if they don't exist.
DataMapper.auto_upgrade!
DataMapper.finalize
