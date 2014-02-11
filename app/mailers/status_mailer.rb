class StatusMailer < ActionMailer::Base
  default from: "craigslist-watcher@your-dns.com"

  def status_email(message)
    recipients  = ['ryan.foster@gmail.com']
    subject     = "Craigslist Housing Parser Error"

    @message = message

    mail(:to => recipients, :subject => subject)
  end
end
