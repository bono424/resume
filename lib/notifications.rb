require 'mail'
require 'pony'


module Trd
  class Notifications
    DEV = '"TRD Dev <trd@mygrad.com.au>'
    SUPPORT = '"MyGrad Support" <support@mygrad.com.au>'
    SIGNUP = '"Jonathan Colak" <jonathan@colak.com.au>'
    FROM = '"MyGrad Support" <support@mygrad.com.au>'

    def self.send_verification_email(email, verification_key)
      to = email
      from = "MyGrad <welcome@mygrad.com.au>"
      link = "http://mygrad.com.au/verify/#{verification_key}"
      subject = "Welcome to MyGrad!"
      body = <<EOS
Before you can start building your profile, you need to confirm your email address.  Just click this link below (or copy and paste it into your address bar):

#{link}

If you have any questions or suggestions, please email us at hello@mygrad.com.au

Good luck and have fun!

MyGrad Team
EOS
      Pony.mail(:to => to, :from => from, :subject => subject, :body => body)
    end

    def self.send_contact_email(from, message)
      subject = "[mygrad] Message from #{from}"

      body =<<EOS
From: #{from} \n
----------------------------------------------------------------------\n\n

Message:\n
#{message} \n
----------------------------------------------------------------------\n\n

Love,\n
mygrad bot
EOS
      Pony.mail(:to => SUPPORT, :from => SUPPORT, :subject => subject, :body => body)
    end

    def self.send_payment_receipt(to, date, amount, plan)
      subject = "[MyGrad] Payment Receipt"

      body =<<EOS
This is a receipt for your subscription with MyGrad. This is only a receipt, no
payment is due. If you have any questions, please contact us anytime at
support@mygrad.com.au. Thank you for your business!

MyGrad RECEIPT - #{date}\n

User: #{to}\n
Plan: #{plan}\n
Amount: USD #{amount}


Thank you!
EOS
      Pony.mail(:to => to, :bcc => DEV, :from => SUPPORT, :subject => subject, :body => body)
    end

    def self.send_welcomeback_email(to, v_key, name)
      subject = "The NEW Resume Drop is here!"

      body =<<EOS
Hi #{name},

Thanks for joining MyGrad. We've been hard at work improving MyGrad. We're proud to say that the new version is now online. We hope you'll find it a lot easier to create your profile and find great opportunities.

To visit your profile, go to the link below (it's unique to you):
http://www.mygrad.com.au/welcomeback/#{v_key}

If you have suggestions, questions, or just want to say hi, please email us at hello@mygrad.com.au

Thanks!
MyGrad Team
EOS
      Pony.mail(:to => to, :from => "'MyGrad' <welcome@mygrad.com.au>", :subject => subject, :body => body)
    end

    def self.send_password_recovery(to, key, name)
      subject = "MyGrad Password Recovery"

      body =<<EOS
Hi #{name},

We've received your request to reset your password. To do so, please visit the following link:\n
http://www.mygrad.com.au/passwordreset/#{key}

If you believe you have received this message in error, please ignore this message. No action is required on your part.

Thanks!\n
MyGrad Team
EOS
      Pony.mail(:to => to, :from => SUPPORT, :subject => subject, :body => body)
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
