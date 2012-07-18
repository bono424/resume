require File.expand_path('models', File.dirname(__FILE__))
require 'date'

module Trd
  class Fixtures
    class << self
      def generate
        output = ""
        if User.first(:email => "chandras@fas.harvard.edu").nil?
          Student.create(
            :email => "chandras@fas.harvard.edu",
            :password => "ba96f8d7c7826112b882637788fc5c81b3eb46d16072dca53fa1fdc2214635cf",
            :salt => "XNYOIM",
            :is_verified => true,
            :verification_key => "ygr6Uo7iXJksJpeVRf2Yxlc3Wri2oMFL",
            :name => "Siddarth Chandrasekaran",
            :school => "Harvard University",
            :gpa => 3.5,
            :gender => "Male",
            :interest1 => "Computers",
            :interest2 => "Haxxors",
            :interest3 => "Art History",
            :major => "Computer Science",
            :minor => "Philosophy",
            :class => "2012",
            :has_done_stages => true,
            :is_employer => false,
            :experiences => [
              Experience.new(
                :position => "Lolcat manager",
                :place => "icanhazcheezburger",
                :desc => "I sat at my desk all day, created Lolcats, posted reviews of Lolcats on the site (Pitchfork-style).",
                :start_date => DateTime.parse("03/2012"),
                :end_date => DateTime.parse("05/2012")),
            Experience.new(
              :position => "Lolcat manager",
              :place => "icanhazcheezburger",
              :desc => "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam ultricies vestibulum placerat. Quisque placerat ipsum ut ante sodales luctus. Sed gravida purus sit amet mi tempus tincidunt viverra nibh consectetur. Donec ac turpis vitae lorem sollicitudin bibendum ac ac nunc. Etiam sodales augue et elit luctus porttitor varius et diam. Proin eget sapien et lorem tristique interdum. Nullam adipiscing tristique lorem. Fusce tincidunt lacinia faucibus. In hac habitasse platea dictumst. Aliquam ut dolor arcu, sit amet rhoncus lectus. Nam elementum ullamcorper sapien in pellentesque. Duis ac purus vestibulum nisi consectetur facilisis id at tellus. Phasellus id leo vitae sem fringilla mollis ut at eros. Morbi quis velit sem, blandit mattis erat. Maecenas quis elit augue, quis scelerisque velit. Donec placerat aliquet justo, vitae vestibulum diam pellentesque ut. In id facilisis urna. Praesent quis tellus venenatis lorem eleifend scelerisque. In hac habitasse platea dictumst.",
              :start_date => DateTime.parse("03/2012"),
              :end_date => DateTime.parse("05/2012"))
            ]
          )
          output += "Student created for chandras@fas.harvard.edu."
        end

        if User.first(:email => "s@siddarthc.com").nil?
          begin
            Employer.create(
              :email => "s@siddarthc.com",
              :password => "ba96f8d7c7826112b882637788fc5c81b3eb46d16072dca53fa1fdc2214635cf",
              :salt => "XNYOIM",
              :is_verified => true,
              :verification_key => "ygr6Uo7iXJksJpeVRf2Yxlc3Wri2oMFL",
              :name => "The Resume Drop",
              :handle => "theresumedrop",
              :url => "http://theresumedrop.com",
              :description => "The Resume Drop helps you connect with top employers and recruiters. We help to put you in a position to be considered for internships and full time positions by the banks, consulting firms, public service groups, and other firms that we partner with.",
              :founded => 2011,
              :address => "33 Oxford Street",
              :state => "Cambridge, MA",
              :zipcode => "02138".to_i,
              :photo => "logo.png",
              :phone => "6179997094"
            )
          rescue Exception => e
            output += e.message
          end
          output += "Employer created for s@siddarthc.com"
        end

        if User.first(:email => "foo@bar.com").nil?
          begin
            Employer.create(
              :email => "foo@bar.com",
              :password => "ba96f8d7c7826112b882637788fc5c81b3eb46d16072dca53fa1fdc2214635cf",
              :salt => "XNYOIM",
              :is_verified => true,
              :verification_key => "ygr6Uo7iXJksJpeVRf2Yxlc3Wri2oMFL",
              :name => "Facebook, Inc.",
              :handle => "facebook",
              :url => "http://www.facebook.com",
              :description => "Millions of people use Facebook everyday to keep up with friends, upload an unlimited number of photos, share links and videos, and learn more about the people they meet.",
              :founded => 2004,
              :address => "1 Infinity Lane,",
              :state => "San Francisco, CA",
              :zipcode => "94116".to_i,
              :photo => "facebook.jpg",
              :phone => "6179997094"
            )
          rescue Exception => e
            raise e
            output += e.message
          end
        end
      end
    end
  end
end
