require 'rubygems'
require 'sinatra'
require 'haml'
require 'stripe'
require 'pony'
require 'aws/s3'
require 'rmagick'

require 'logger'

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
  def  title(str = nil)
    # helper for formatting page title
    if str
      str + ' | The Resume Drop'
    else
      'The Resume Drop'
    end
  end

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

  def nl2br(s)
        s.gsub(/\n/, '<br>')
  end

  def redirect_students()
    redirect '/' if @user.nil?
    raise Sinatra::NotFound unless (@user.type == Employer) || @user.is_admin
  end

  def all_interests()
    ['Advertising / PR', 'Consulting', 'Education', 'Entrepreneurship', 'Finance', 'Government / Military', 'Healthcare', 'Media / Entertainment', 'Non-Profit', 'Other', 'Real Estate', 'Technology']
  end
end

# used for debugging
configure do
    LOGGER = Logger.new("sinatra.log")
end
 
helpers do
    def logger
        LOGGER
    end
    def look(object)
        if not ENV['RACK_ENV'] == 'production'
            logger.info "#{object.inspect}"
        else
            puts "#{object.inspect}"
        end
    end
end

before do
  @success, @error = nil
  user_id = session[:user]
  @user = User.get(user_id)
end

get '/' do
  @title = title 'Welcome'
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

post '/upload' do
  begin
    unless params['file'] && (tmpfile = params['file'][:tempfile]) && (name = params['file'][:filename])
        redirect '/profile' unless @user.nil?
    end

    # generate name and determine filetype
    ext = File.extname(params['file'][:filename])
    name = "#{(Time.now.to_i.to_s + Time.now.usec.to_s).ljust(16, '0')}#{ext}"

    case params[:action]
    when 'photo'
      unless ext.eql?('.jpg') or ext.eql?('.png') or ext.eql?('.gif') or ext.eql?('.jpeg')
          raise TrdError.new("Profile images must be of type .jpg, .png, or .gif")
      end
      begin
        #connect to s3
        AWS::S3::Base.establish_connection!(
        :access_key_id     => settings.s3_key,
        :secret_access_key => settings.s3_secret)

        #resize image before storing
        img = Magick::Image.read(params['file'][:tempfile].path).first
        img.resize_to_fill(300,300).write(name)

        #store it
        AWS::S3::S3Object.store(name,open(name),settings.bucket,:access => :public_read)     
      rescue
        raise TrdError.new("Upload to S3 failed.")
      end
      # if successful, set user as profile image
      @user.update(:photo => name) 

    when 'resume'
      unless ext.eql?('.pdf')
          raise TrdError.new("Resumes must be of type .pdf") 
      end
      begin
          AWS::S3::Base.establish_connection!(
          :access_key_id     => settings.s3_key,
          :secret_access_key => settings.s3_secret)
          AWS::S3::S3Object.store(name,open(tmpfile),settings.bucket,:access => :public_read)     
      rescue
        raise TrdError.new("Upload to S3 failed.")
      end
      # if successful, set user as profile image
      @user.update(:resume=> name) 
    end

    redirect '/profile'
  rescue TrdError => e
      @error = e.message
      @success = nil
      if @user.type == Student
          haml :student_profile, :layout => :'layouts/application'
      else
          haml :employer_profile, :layout => :'layouts/application'
      end
  end
end

get '/verify/:key' do
  @title = title 'Verify'
  begin
    redirect '/profile' unless @user.nil?
    e = TrdError.new("Invalid verification key.")
    raise e if params[:key].nil?
    user = nil

    user = User.first(:verification_key => params[:key])

    raise e if user.nil?
    raise e if user.verification_key != params[:key]

    if user.type == Student
      user.update(:is_verified => true)
      @success = "You have successfully verified your account. You can now <a href='/'>log in</a>."
    else
      Stripe.api_key = "sk_test_aR1DCWnDqi5OlkU04ZyH3tp3"
      c = Stripe::Customer.retrieve(user.account_id)
      c.update_subscription(:plan => user.plan)

      user.update(:is_verified => true)
      @success = "You have successfully verified your account and your account has been charged. You can now <a href='/'>log in</a>."
    end

    haml :verify, :layout => :'layouts/message'
  rescue Stripe::StripeError
    @error = "We were unable to process your payment. Please email support@theresumedrop.com for more information."
    @success = nil
    haml :verify, :layout => :'layouts/message'
  rescue TrdError => e
    @error = e.message
    @success = nil
    haml :verify, :layout => :'layouts/message'
  end
end

get '/profile' do
  @title = title @user.name
  @interests = all_interests
  redirect '/' if @user.nil?
  if @user.type == Employer
    @postings = Posting.all(:employer_id => @user.id, :deadline.gt => Time.now, :deleted.not => 'true', :order => [ :deadline.asc ])
    haml :employer_profile, :layout => :'layouts/application'
  else
    @experiences = Experience.all(:student_id => @user.id, :deleted.not => 'true', :order => [ :end_date.desc ])
    @extracurriculars = Extracurricular.all(:student_id => @user.id, :deleted.not => 'true', :order => [ :end_date.desc ])
    haml :student_profile, :layout => :'layouts/application'
  end
end

post '/profile' do
  @interests = all_interests
  redirect '/' if @user.nil?
  begin
    student_actions = %w{personal work education extracurricular}
    employer_actions = %w{about posting}

    look(@user)

    if @user.type == Student
      look(@user)
      look(params)
      unless student_actions.include? params[:action]
          raise TrdError.new("Sorry, an error occured.")
      end
      case params[:action]
      when "education"
        # validate inputs
        if params[:gpa].is_a? Numeric
          raise TrdError.new("Your GPA must be a number.")
        end

        begin
            class_year = Date.strptime(params[:class], "%Y")
        rescue
            raise TrdError.new("Your class year must be a valid, numeric date (YYYY).")
        end

        @user.update(:school => params[:school], :major => params[:major], :minor => params[:minor], :class => class_year, :gpa => params[:gpa])
      
      when "personal"
        # make sure interests are valid
        [:interest1, :interest2, :interest3].each do |i|
          unless (params[i] == "") || (all_interests.include? params[i])
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
      haml :student_profile, :layout => :'layouts/application'
      
    else
      unless employer_actions.include? params[:action]
          raise TrdError.new("Sorry, an error occured.")
      end
      case params[:action]
      when "about"
        description = nl2br(params[:description])
        @user.update(:description => params[:description], :address => params[:address], :city => params[:city], :state => params[:state], :zipcode => params[:zipcode])
      when "posting"
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
      haml :student_profile, :layout => :'layouts/application'
    else
      haml :employer_profile, :layout => :'layouts/application'
    end
  end
end

get '/profile/:id' do
  redirect '/' if @user.nil?

  @profile_user = User.get(params[:id])
  redirect '/profile' if @user.id == params[:id].to_i

  if @user.type == Employer
    @student = Student.get(params[:id])
    raise TrdError.new("Sorry, this page does not exist.") if @student.nil?

    @experiences = Experience.all(:student_id => @student.id)
    @extracurriculars = Extracurricular.all(:student_id => @student.id)
    @title = title @student.name
    haml :other_student_profile, :layout => :'layouts/application'
  else
    @employer = Employer.first(:handle=> params[:id])
    raise TrdError.new("Sorry, this page does not exist.") if @employer.nil?

    @postings = Posting.all(:employer_id => @employer.id)
    @title = title @employer.name
    haml :other_employer_profile, :layout => :'layouts/application'
  end
end

get '/profile/delete/:type/:id' do
  begin
    case params[:type]
    when 'experience'
      o = Experience.get(params[:id])
      raise TrdError.new("We could not process that request.") unless o.student_id == @user.id
      o.update(:deleted => true)
    when 'extracurricular'
      o = Extracurricular.get(params[:id])
      raise TrdError.new("We could not process that request.") unless o.student_id == @user.id
      o.update(:deleted => true)
    when 'posting'
      o = Posting.get(params[:id])
      raise TrdError.new("We could not process that request.") unless o.employer_id == @user.id
      o.update(:deleted => true)
    end
    redirect '/profile'
  rescue TrdError => e
    @error = e.message
    haml :error, :layout => :'layouts/message'
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

get '/fixtures' do
  Fixtures.generate
end

get '/logout' do
  session.clear
  redirect '/'
end

get '/employers' do
  @title = title 'Employers'
  begin
    employers = Employer.all(:is_verified => true, :type => Employer)
    raise TrdError.new("Sorry, we have no companies listed.") if employers.length.zero?
    @employers = employers
    haml :employers, :layout => :'layouts/application'
  rescue TrdError => e
    @error = e.message
    @success = nil
    haml :employers, :layout => :'layouts/application'
  end
end

get '/jobs' do
  @title = title 'Jobs'
  begin
    postings = Posting.all(:deadline.gt => Time.now, :deleted.not => 'true', :order => [ :deadline.asc ])
    raise TrdError.new("Sorry, we have no jobs listed currently.") if postings.length.zero?
    @postings = postings 
    haml :jobs, :layout => :'layouts/application'
  rescue TrdError => e
    @error = e.message
    @success = nil
    haml :jobs, :layout => :'layouts/application'
  end
end

get '/pricing' do
  @title = title 'Pricing'
  haml :pricing, :layout => :'layouts/application'
end

get '/subscribe' do
  redirect '/pricing'
end

get '/subscribe/:plan' do
  @title = title 'Subscribe'
  haml :subscribe, :layout => :'layouts/subscribe'
end

post '/subscribe/:plan' do
  begin
    validate(params, [:token, :email, :name, :password, :handle, :url, :phone])
    user = User.get(:email => params[:email])
    raise TrdError.new("This account is already registered. Please contact us at support@theresumedrop.com to delete this account.") unless user.nil?

    Stripe.api_key = "sk_test_aR1DCWnDqi5OlkU04ZyH3tp3"
    customer = Stripe::Customer.create(
      :description => "Customer for #{params[:name]}",
      :email => params[:email],
      :card => params[:token]
    )

    salt = random_string(6)
    hash = hash(params[:password], salt)

    verification_key = random_string(32)

    Employer.create(:email => params[:email], :password => hash, :salt => salt, :verification_key => verification_key, :name => params[:name], :email => params[:email], :phone => params[:phone], :account_id => customer.id, :plan => params[:plan], :handle => params[:handle], :url => params[:url])
    Notifications.send_verification_email(params[:email], verification_key)

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

get '/stripe_test' do
  begin
    Stripe.api_key = "sk_test_aR1DCWnDqi5OlkU04ZyH3tp3"
    Stripe::Charge.create(
        :amount => 1500, # $15.00 this time
        :currency => "usd",
        :customer => @user.account_id
    )
    @success = "You've charged the account."
    haml :subscribe, :layout => :'layouts/subscribe'
  rescue Stripe::StripeError
    @error = "We were unable to process your payment. Please email support@theresumedrop.com for more information."
    @success = nil
    haml :subscribe, :layout => :'layouts/subscribe'
  end
end

# Static pages.

get '/about' do
  @title = title 'About'
  haml :about, :layout => :'layouts/application'
end

get '/privacy' do
  @title = title 'Privacy'
  haml :privacy, :layout => :'layouts/application'
end

get '/terms' do
  @title = title 'Terms'
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
  @title = title 'Search'
  begin
    if @user.type == Employer
      if params.empty?
        haml :search, :layout => :'layouts/application'
      else
        
        # Generate query string. I know this sucks. Bear with me.
        @results = Student.all 
        @results = @results.all(:conditions => ["name ILIKE ?", "%#{params[:name]}%"]) unless params[:name] == ""
        @results = @results.all(:conditions => ["school ILIKE ?", "%#{params[:school]}%"]) unless params[:school] == ""
        @results = @results.all(:conditions => ["class = ?", "%#{params[:class]}%"]) unless params[:class] == ""
        @results = @results.all(:gpa.gte => params[:gpa]) unless params[:gpa] == ""
        @results = @results.all(:conditions => ["major ILIKE ?", "%#{params[:major]}%"]) unless params[:major] == ""
        @results = @results.all(:conditions => ["minor ILIKE ?", "%#{params[:minor]}%"]) unless params[:minor] == ""
        @results = @results.all(:conditions => ["interest1 ILIKE ?", "%#{params[:interest]}%"]) unless params[:interest1] == ""
        # @results = @results.all(:name.like => "%#{params[:name]}%")
        # @results = @results.all(:school.like => "%#{params[:school]}%")
        # if not params[:class].empty?
        #   @results = @results.all(:class => params[:class])
        # end
        # if not params[:gpa].empty?
        #   @results = @results.all(:gpa => params[:gpa])
        # end
        # @results = @results.all(:major.like => "%#{params[:major]}%")
        # @results = @results.all(:minor.like => "%#{params[:minor]}%")
        # if not params[:interest1] == 'Interest One'
        #   @results = @results.all(:interest1 => "%#{params[:interest1]}%")
        # end
        # if not params[:interest2] == 'Interest Two'
        #   @results = @results.all(:interest2 => "%#{params[:interest2]}%")
        # end
        # if not params[:interest3] == 'Interest Three'
        #   @results = @results.all(:interest3 => "%#{params[:interest3]}%")
        # end

        # if no results found, show error.
        raise TrdError.new("Sorry, we couldn't find anything with the parameters you specified.") if @results.nil? || @results.empty?
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
