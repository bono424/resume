require 'mail'

module Trd
  class Notifications
    DEV = '"Scott Sansovich" <ssansovich@gmail.com>, "Siddarth Chandrasekaran" <chandrasekaran.siddarth@gmail.com>'
    SIGNUP = '"Scott Sansovich" <ssansovich@gmail.com>, "Siddarth Chandrasekaran" <chandrasekaran.siddarth@gmail.com>'
    ALL = '"Scott Sansovich" <ssansovich@gmail.com>, "Siddarth Chandrasekaran" <chandrasekaran.siddarth@gmail.com>'

    def self.send_subscription_notification(s)
      subject = "[TheResumeDrop] Subscription notification"
      body = <<EOS
Greetings!

New subscription on TheResumeDrop! Here are the details:
#{s.attributes}

Love,
TheResumeDrop bot
EOS
      email(ALL, "bot@theresumedrop.com", subject, body)
    end

    def self.send_verification_email(user)
      return if user.nil?
      to = user.email
      from = "welcome@theresumedrop.com"
      link = "http://theresumedrop.com/verify/#{user.verification_key}"
      subject = "Welcome to The Resume Drop!"
      body = <<EOS
Before you can log in, you have to confirm your email address. To confirm your email address, click here: #{link}

Thanks,
The Resume Drop Team
EOS
      mail(to, from, subject, body)
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