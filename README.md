Looking for housing in Boulder is a bit of a nightmare. Separating the signal from the noise is a taxing chore, so I decided to come up with a little Craigslist parser to try and isolate only the information I cared about.

I wrote a parser (and accompanying web service to display results and persist records to a database) and found that Craigslist blocks requests coming from AWS servers. I then re-architected the application to have a standalone parser that runs on a Raspberry Pi to get around Craigslist blocking. This task is automated to run every few hours and pull out contextually relevant data or filter out results that I've blacklisted.

This makes looking for housing in Boudler a much more pleasant experience.

(Keep in mind that Craigslist's TOS restricts parsing their data)

![parsed results](https://dl.dropboxusercontent.com/spa/lbv7q0z27j14pgl/4st6xrr8.png)
