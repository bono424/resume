require 'mail'
require 'pony'


module Trd
  class Notifications
    DEV = '"Scott Sansovich" <ssansovich@gmail.com>'
    SUPPORT = '"The Resume Drop Support" <support@theresumedrop.com>'
    SIGNUP = '"Scott Sansovich" <ssansovich@gmail.com>'
    FROM = '"The Resume Drop Support" <support@theresumedrop.com>'

    def self.send_verification_email(email, verification_key)
      to = email
      from = "The Resume Drop <welcome@theresumedrop.com>"
      link = "http://theresumedrop.com/verify/#{verification_key}"
      subject = "Welcome to The Resume Drop!"
      body = <<EOS
Before you can start building your profile, you need to confirm your email address.  Just click this link below (or copy and paste it into your address bar):

#{link}

If you have any questions or suggestions, please email us at hello@theresumedrop.com

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
      Pony.mail(:to => SUPPORT, :from => SUPPORT, :subject => subject, :body => body)
    end

    def self.send_payment_receipt(to, date, time, amount, name, plan)
      subject = "[The Resume Drop] Payment Receipt"

      body =<<EOS
Hi #{name},

This is a receipt for your subscription with The Resume Drop. This is only a receipt, no
payment is due. If you have any questions, please contact us anytime at
support@theresumedrop.com. Thank you for your business!

THE RESUME DROP RECEIPT - #{date}\n

User: #{to}\n
Plan: #{plan}\n
Amount: USD #{amount}


Thank you!
EOS
      Pony.mail(:to => DEV, :from => SUPPORT, :subject => subject, :body => body)
    end

    def self.send_welcomeback_email(to, v_key, name)
      subject = "The NEW Resume Drop is here!"

      body =<<EOS
Hi #{name},

Thanks for joining The Resume Drop. We've been hard at work improving The Resume Drop. We're proud to say that the new version is now online. We hope you'll find it a lot easier to create your profile and find great opportunities.

To visit your profile, go to the link below (it's unique to you):
http://www.theresumedrop.com/welcomeback/#{v_key}

If you have suggestions, questions, or just want to say hi, please email us at hello@theresumedrop.com

Thanks!
The Resume Drop Team
EOS
      Pony.mail(:to => to, :from => "'The Resume Drop' <welcome@theresumedrop.com>", :subject => subject, :body => body)
    end

    def self.send_dump(variable)
      subject = "[TRD] Variable dump"
      body =<<EOS
      #{variable}
EOS
      Pony.mail(:to => DEV, :from => SUPPORT, :subject => subject, :body => body)
    end

  end
end
