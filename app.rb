require 'rubygems'
require 'sinatra'
require 'haml'
require 'stripe'
require 'pony'
require 'aws/s3'

# s3
set :bucket, 'trd-assets'
set :s3_key, 'AKIAIQGNVCLXSVJ6JI4Q'
set :s3_secret, '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'


# Helpers
require './lib/render_partial'
require File.expand_path('lib/exceptions', File.dirname(__FILE__))
require File.expand_path('lib/notifications', File.dirname(__FILE__))
require File.expand_path('lib/fixtures', File.dirname(__FILE__))
require File.expand_path('lib/models', File.dirname(__FILE__))

require File.expand_path('lib/mail', File.dirname(__FILE__))
# require File.expand_path('lib/production', File.dirname(__FILE__))
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

    # unless params[:email].end_with? ".edu"
    #   raise TrdError.new("Sorry, only students can register with The Resume Drop.")
    # end

    @user = Student.first(:email => params[:email])
    raise TrdError.new("Email is already registered.") unless @user.nil?

    salt = random_string(6)
    hash = hash(params[:password], salt)

    verification_key = random_string(32)

    # Create profile and send email
    user = Student.create(:email => params[:email], :password => hash, :salt => salt, :verification_key => verification_key, :name => params[:name], :email => params[:email])
    Notifications.send_verification_email(user.email, user.verification_key)

    @success = "You've successfully registered. Check your email for a verification email."

    haml :index, :layout => :'layouts/index'
  rescue TrdError => e
    @error = e.message
    @success = nil
    haml :index, :layout => :'layouts/index'
  end
end

post '/uploadphoto' do
    unless params['photo'] && (tmpfile = params['photo'][:tempfile]) && (name = params['photo'][:filename])
        haml :index, :layout => :'layouts/index'
    end

    # generate image name
    name = "#{(Time.now.to_i.to_s + Time.now.usec.to_s).ljust(16, '0')}#{File.extname(params['photo'][:filename])}"

    while blk = tmpfile.read(65536)
        AWS::S3::Base.establish_connection!(
        :access_key_id     => settings.s3_key,
        :secret_access_key => settings.s3_secret)
        AWS::S3::S3Object.store(name,open(tmpfile),settings.bucket,:access => :public_read)     
    end

    # if successful, set user as profile image
    @user.update(:photo => name) 

    redirect '/profile' unless @user.nil?
end

get '/verify/:key' do
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
        puts "Hello, works!"
        [:position, :place, :start_date, :end_date, :desc].each do |i|
          raise TrdError.new("Please enter all the fields.") if params[i].nil? || params[i] == ""
        end
        work = @user.experiences.new
        work.position = params[:position]
        work.place = params[:place]
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
        puts "Hello, extracurriculars!"
        [:position, :place, :start_date, :end_date, :desc].each do |i|
          raise TrdError.new("Please enter all the fields.") if params[i].nil? || params[i] == ""
        end
        exp = @user.extracurriculars.new
        exp.position = params[:position]
        exp.place = params[:place]
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
        [:position, :place, :start_date, :end_date, :description, :class, :qualifications, :contact_name, :contact_email].each do |i|
          raise TrdError.new("Please enter all the fields.") if params[i].nil? || params[i] == ""
        end
        posting = @user.postings.new
        posting.position = params[:position]
        posting.place = params[:place]
        posting.description = params[:description]
        posting.class = params[:class]
        posting.qualifications = params[:qualifications]
        posting.contact_name = params[:contact_name]
        posting.contact_email = params[:contact_email]
        begin
          posting.deadline = Date.strptime(params[:deadline], "%d/%m/%Y")
          posting.start_date= Date.strptime(params[:start_date], "%d/%m/%Y")
          posting.end_date = Date.strptime(params[:end_date], "%d/%m/%Y")
        rescue
          raise TrdError.new("Invalid date (DD/MM/YYYY required).")
        end
        posting.deadline = params[:deadline]
        posting.save
        @user.save
      end
      haml :employer_profile, :layout => :'layouts/application'
    end
  rescue TrdError => e
    @error= e.message
    @success = nil
    if @user.type == Student
      haml :profile, :layout => :'layouts/application'
    else
      haml :employer_profile, :layout => :'layouts/application'
    end
  end
end

get '/profile/delete/:type/:id' do
  if params[:type] == 'work'
    Experience.get(params[:id]).destroy
  end
  if params[:type] == 'extracurricular'
    Extracurricular.get(params[:id]).destroy
  end
  if params[:type] == 'posting'
    Posting.get(params[:id]).destroy
  end
  redirect to('/profile')
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
  begin
    if @user.type == Employer
      if params.empty?
        haml :search, :layout => :'layouts/application'
      else
        
        # Generate query string. I know this sucks. Bear with me.
        @results = Student.all(:name.like => "%#{params[:name]}%")
        @results = @results.all(:school.like => "%#{params[:school]}%")
        if not params[:class].empty?
          @results = @results.all(:class => params[:class])
        end
        if not params[:gpa].empty?
          @results = @results.all(:gpa => params[:gpa])
        end
        @results = @results.all(:major.like => "%#{params[:major]}%")
        @results = @results.all(:minor.like => "%#{params[:minor]}%")
        if not params[:interest1] == 'Interest One'
          @results = @results.all(:interest1 => "%#{params[:interest1]}%")
        end
        if not params[:interest2] == 'Interest Two'
          @results = @results.all(:interest2 => "%#{params[:interest2]}%")
        end
        if not params[:interest3] == 'Interest Three'
          @results = @results.all(:interest3 => "%#{params[:interest3]}%")
        end
  
        # if no results found, show error.
        raise TrdError.new("Sorry, we couldn't find anything with the parameters you specified.") if @results.empty?
        haml :search, :layout => :'layouts/application'
      end
    else
      redirect '/profile'
    end
  rescue TrdError => e
      @error = e.message
      haml :search, :layout => :'layouts/application'
  end
end

get '/splash' do
    haml :splash, :layout => :'layouts/index'
end
