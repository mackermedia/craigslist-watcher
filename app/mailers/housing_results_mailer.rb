class HousingResultsMailer < ActionMailer::Base
  default from: "craigslist-watcher@your-dns.com"

  def notification_email(batch)
    recipients  = ['ryan.foster@gmail.com']
    subject     = "Craigslist Housing Update"

    @batch = batch

    mail(:to => recipients, :subject => subject)
  end
end
