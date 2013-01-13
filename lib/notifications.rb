require 'mail'
require 'pony'


module Trd
  class Notifications
    DEV = '"Scott Sansovich" <ssansovich@gmail.com>'
    SUPPORT = '"Scott Sansovich" <ssansovich@gmail.com>'
    SIGNUP = '"Scott Sansovich" <ssansovich@gmail.com>'
    ALL = '"Scott Sansovich" <ssansovich@gmail.com>'
    FROM = '"Resume Drop" <info@theresumedrop.com>'

    def self.send_verification_email(email, verification_key)
      return if user.nil?
      to = email
      from = "The Resume Drop <welcome@theresumedrop.com>"
      link = "http://theresumedrop.com/verify/#{verification_key}"
      subject = "Welcome to The Resume Drop!"
      body = <<EOS
Before you can log in, you have to confirm your email address. To confirm your email address, click here: #{link}

Thanks,
The Resume Drop Team
EOS
      body = <<EOS
Welcome to The Resume Drop!

Before you can start building your profile, you need to confirm your email address.  Just click this link below (or copy and paste it into your address bar):

#{link}

If you have any questions or suggestions, please let us know! Send an email to either scott@theresumedrop.com or damilare.sonoike@theresumedrop.com

Good luck and have fun!

The Resume Drop Team
EOS
      Pony.mail(:to => to, :from => from, :subject => subject, :body => body)
    end

    def self.send_contact_email(from, message)
      subject = "[TheResumeDrop] Message from #{from}"

      body =<<EOS
From: #{from} \n
----------------------------------------------------------------------\n\n

Message:\n
#{message} \n
----------------------------------------------------------------------\n\n

Love,\n
TheResumeDrop bot
EOS
      Pony.mail(:to => SUPPORT, :from => "'TRD Bot' <bot@theresumedrop.com>", :subject => subject, :body => body)
    end

    def self.send_breakage_notification(user, e)
      return if e.nil?
      subject = "[TheResumeDrop] Breakage notification"

      user_str = user.nil? ? "User not logged in." : user.attributes.to_s
      body =<<EOS
Breakage on TheResumeDrop: #{e.name}
----------------------------------------------------------------------
Backtrace:

#{e.backtrace}
----------------------------------------------------------------------
User details:

#{user_str}
----------------------------------------------------------------------
Love,
TheResumeDrop bot
EOS
      email(DEV, "bot@theresumedrop.com", subject, body)
    end

    def self.send_signup_notification(user)
      subject = "[TheResumeDrop] Sign-up notification"
      body = <<EOS
Greetings!

New sign up on TheResumeDrop! Here's the user:
#{user.attributes}

Love,
TheResumeDrop bot
EOS
      email(SIGNUP, "bot@theresumedrop.com", subject, body)
    end
    private

    def self.email(to, from, subject, body)
      mail = Mail.new
      mail[:from] = from
      mail[:to] = to
      mail[:subject] = subject
      mail[:body] = body
      mail.deliver!
    end
  end
end
