# coding: utf-8

require 'json'
require 'net/http'
require 'openssl'
require 'rss'
require 'time'
require 'yaml'


def get_rss
  rss_url   = URI.parse('http://sengokuixa.jp/rss/news.php')
  RSS::Parser.parse(Net::HTTP.get(rss_url))
end

def check_date(rss)
  file_name = 'update_time.txt'
  new_date = rss.channel.pubDate
  old_date = nil
  if File.exist?(file_name)
    File.open(file_name, 'r') do |f|
      old_date = Time.rfc2822(f.read)
    end
  else
    old_date = Time.now - 365*24*60*60
  end
  if new_date == old_date
    return true
  else
    File.open(file_name, 'w') do |f|
      f.puts(new_date)
    end
    return false
  end
end

def post_slack(item)
  file_name = 'config.yml'
  slack_url = ''
  channel = ''
  username = ''
  if File.exist?(file_name)
    config = YAML.load_file(file_name)
    slack_url = URI.parse(config['url'])
    channel = config['channel']
    username = config['username']
  else
    return
  end

  title = item.title
  link = item.link
  payload = {
    'channel' => '#' + channel,
    'username' => username,
    'text' => title + "
      " + link
  }

  https = Net::HTTP.new(slack_url.host, slack_url.port)
  https.use_ssl = true
  https.verify_mode = OpenSSL::SSL::VERIFY_NONE
  req = Net::HTTP::Post.new(slack_url.request_uri)
  req['Content-Type'] = 'application/json'
  req.body = JSON.generate(payload)
  res = https.request(req)
end

def main
  rss = get_rss
  if check_date(rss)
    return
  end
  post_slack(rss.channel.item(0))
end

main()