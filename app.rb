require 'rubygems'
require 'sinatra'
require 'haml'
require 'stripe'

# Helpers
require './lib/render_partial'
require File.expand_path('lib/exceptions', File.dirname(__FILE__))
require File.expand_path('lib/notifications', File.dirname(__FILE__))
require File.expand_path('lib/fixtures', File.dirname(__FILE__))
require File.expand_path('lib/models', File.dirname(__FILE__))

# Set Sinatra variables
set :app_file, __FILE__
set :root, File.dirname(__FILE__)
set :views, 'views'
set :public_folder, 'public'
set :haml, {:format => :html5} # default Haml format is :xhtml

# Sessions for login management
enable :sessions

include Trd

helpers do
  def random_string(len)
    str = ''
    len.times do
      str << (i = Kernel.rand(62)
      i += ((i < 10) ? 48 : ((i < 36) ? 55 : 61 ))).chr
    end
    str
  end

  def hash(string, salt)
    Digest::SHA256.hexdigest("#{string}:#{salt}")
  end

  def validate(p, req)
    req.each { |r| raise TrdError.new("Field '#{r}' missing.") if p[r].nil? }
  end

  def redirect_students()
    redirect '/' if @user.nil?
    raise Sinatra::NotFound unless @user.is_employer || @user.is_admin
  end

  def all_interests()
    ['Advertising / PR', 'Consulting', 'Education', 'Entrepreneurship', 'Finance', 'Government / Military', 'Healthcare', 'Media / Entertainment', 'Non-Profit', 'Other', 'Real Estate', 'Technology']
  end
end

before do
  @success, @error = nil
  user_id = session[:user]
  @user = User.get(user_id)
end

get '/' do
  redirect '/profile' unless @user.nil?
  haml :index, :layout => :'layouts/index'
end

post '/' do
  begin
    validate(params, [:password, :name, :email])

    unless params[:email].end_with? ".edu"
      raise TrdError.new("Sorry, only students can register with The Resume Drop.")
    end

    user = Student.first(:email => params[:email])
    raise TrdError.new("Email is already registered.") unless user.nil?

    salt = random_string(6)
    hash = hash(params[:password], salt)

    verification_key = random_string(32)

    Student.create(:email => params[:email], :password => hash, :salt => salt, :verification_key => verification_key, :name => params[:name], :email => params[:email])

    @success = "You've successfully registered. Check your email for a verification email."

    haml :index, :layout => :'layouts/index'
  rescue TrdError => e
    @error = e.message
    @success = nil
    haml :index, :layout => :'layouts/index'
  end
end

get '/verify' do
  begin
    redirect '/profile' unless @user.nil?
    e = TrdError.new("Invalid verification key.")
    raise e if params[:key].nil?
    user = nil

    user = Student.first(:verification_key => params[:key])
    if user.nil?
      user = Employer.first(:verification_key => params[:key])
      raise e if user.nil?
    end

    raise e if user.verification_key != params[:key]

    user.update(:is_verified => true)
    @success = "User successfully verified. You can log in now."
    haml :verify, :layout => :'layouts/message'
  rescue TrdError => e
    @error = e.message
    @success = nil
    haml :verify, :layout => :'layouts/message'
  end
end

get '/profile' do
  @interests = all_interests
  redirect '/' if @user.nil?
  if @user.type == Employer
    haml :employer_profile, :layout => :'layouts/application'
  else
    haml :profile, :layout => :'layouts/application'
  end
end

post '/profile' do
  @interests = all_interests
  redirect '/' if @user.nil?
  begin
    student_actions = %w{personal work education extracurricular}

    if @user.type == Student
      unless student_actions.include? params[:action]
          raise TrdError.new("")
      end
      case params[:action]
      when "education"
        @user.update(:school => params[:school], :major => params[:major], :minor => params[:minor], :class => params[:class], :gpa => params[:gpa])
      when "personal"
        # make sure interests are valid
        [:interest1, :interest2, :interest3].each do |i|
          unless all_interests.include? params[i] || params[i].nil?
            raise TrdError.new("Invalid interest selection: #{params[i]}. Please try again.")
          end
        end
        # updatasaurus
        @user.update(:secondary_email => params[:secondary_email], :interest1 => params[:interest1], :interest2 => params[:interest2], :interest3 => params[:interest3])
      when "work"
        [:position, :place, :start_date, :end_date, :desc].each do |i|
          raise TrdError.new("Please enter all the fields.") if params[i].nil? || params[i] == ""
        end
        work = @user.experiences.new
        work.position = params[:position]
        work.place = params[:position]
        begin
          work.start_date = Date.strptime(params[:start_date], "%m/%Y")
          work.end_date = Date.strptime(params[:end_date], "%m/%Y")
        rescue
          raise TrdError.new("Invalid date (MM/YYYY required).")
        end
        work.desc = params[:desc]
        work.save
        @user.save
      when "extracurricular"
        [:position, :place, :start_date, :end_date, :desc].each do |i|
          raise TrdError.new("Please enter all the fields.") if params[i].nil? || params[i] == ""
        end
        exp = @user.extracurriculars.new
        exp.position = params[:position]
        exp.place = params[:position]
        begin
          exp.start_date = Date.strptime(params[:start_date], "%m/%Y")
          exp.end_date = Date.strptime(params[:end_date], "%m/%Y")
        rescue
          raise TrdError.new("Invalid date (MM/YYYY required).")
        end
        exp.desc = params[:desc]
        exp.save
        @user.save
      end
      haml :profile, :layout => :'layouts/application'
    else
      case params[:action]
      when "info"
        @user.update(:url => params[:url], :founded => params[:founded], :description => params[:description], :address => params[:address], :city => params[:city], :state => params[:state], :zipcode => params[:zipcode], :phone => params[:phone])
      when "listing"
        [:name, :description, :class, :qualifications, :location, :deadline, :contact].each do |i|
          raise TrdError.new("Please enter all the fields.") if params[i].nil? || params[i] == ""
        end
        posting = @user.postings.new
        postion.name = params[:name]
        posting.description = params[:description]
        posting.class = params[:class]
        posting.qualifications = params[:qualification]
        posting.location = params[:location]
        begin
          posting.deadline = Date.strptime(params[:deadline], "%d/m/%Y")
        rescue
          raise TrdError.new("Invalid date (DD/MM/YYYY required).")
        end
        posting.deadline = params[:deadline]
        posting.save
        @user.save
      end
    end
  rescue TrdError => e
    @error= e.message
    @success = nil
    haml :profile, :layout => :'layouts/application'
  end
end

post '/login' do
  begin
    redirect '/profile' unless @user.nil?
    validate(params, [:email, :password])
    user = User.first(:email => params[:email])

    # make sure email is valid
    if user.nil?
      raise TrdError.new("Invalid login credentials.")
    end

    # check password
    pass = hash(params[:password], user.salt)
    raise TrdError.new("Invalid login credentials.") if pass != user.password

    # make sure user is verified
    raise TrdError.new("User is not verified.") unless user.is_verified

    # insert info into sessions
    session[:user] = user.id
    redirect '/profile'
  rescue TrdError => e
    @error = e.message
    @success = nil
    haml :index, :layout => :'layouts/index'
  end
end

get '/update/1' do
  begin

  rescue

  end
end

get '/employers/:handle' do
  @employer = Employer.first(:handle => params[:handle])
  raise Sinatra::NotFound if @employer.nil?
  haml :employer_page, :layout => :'layouts/application'
end

get '/fixtures' do
  Fixtures.generate
end

get '/logout' do
  session.clear
  redirect '/'
end

get '/employers' do
  begin
    employers = Employer.all(:is_verified => true, :is_employer => true)
    raise TrdError.new("Sorry, we have no companies listed.") if employers.length.zero?
    @employers = employers
    haml :employers, :layout => :'layouts/application'
  rescue TrdError => e
    @error = e.message
    @success = nil
    haml :employers, :layout => :'layouts/application'
  end
end

get '/subscribe' do
  haml :subscribe, :layout => :'layouts/subscribe'
end

post '/subscribe' do
  begin
    validate(params, [:token, :email, :name, :password, :handle, :url])
    user = User.get(:email => params[:email])
    raise TrdError.new("This account is already registered. Please contact us at support@theresumedrop.com to delete this account.") unless user.nil?

    Stripe.api_key = "pPUOTFfVZxBNBoDM9u3zY60XECyLzDFU"
    Stripe::Customer.create(
      :description => "Customer for #{params[:email]}",
      :email => params[:email],
      :card => params[:token]
    )

    salt = random_string(6)
    hash = hash(params[:password], salt)

    verification_key = random_string(32)

    Employer.create(:email => params[:email], :password => hash, :salt => salt, :verification_key => verification_key, :name => params[:name], :email => params[:email], :phone => params[:phone])

    @success = "You've successfully registered. Please wait to hear back from us to verify your account."

    # Notifications.send_subscription_notification(s)
    haml :subscribe, :layout => :'layouts/subscribe'
  rescue TrdError => e
    @error = e.message
    @success = nil
    haml :subscribe, :layout => :'layouts/subscribe'
  rescue Stripe::StripeError
    @error = "We were unable to process your payment. Please email support@theresumedrop.com for more information."
    @success = nil
    haml :subscribe, :layout => :'layouts/subscribe'
  end
end

# Static pages.

get '/about' do
  haml :about, :layout => :'layouts/application'
end

get '/privacy' do
  haml :privacy, :layout => :'layouts/application'
end

get '/terms' do
  haml :terms, :layout => :'layouts/application'
end

not_found do
  @error = "The page you requested was not found."
  haml :error, :layout => :'layouts/message'
end

error do
  haml :error, :layout => :'layouts/message'
end

get '/search' do
  if @user.type == Employer
    haml :search, :layout => :'layouts/application'
  else
    redirect '/profile'
  end
end
