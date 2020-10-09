require 'faraday'
require 'base64'
require 'json'
require 'digest/md5'
require 'uri'

user_id, filepath, = ARGV
contents = File.read(filepath, nil)
File.open(filepath, 'rb', &:read)
digest = Digest::MD5.new
digest.update(contents)
checksum = Base64.strict_encode64(digest.digest)

puts 'POST /api/direct_uploads'
res = Faraday.new(url: 'http://localhost:3000').post do |req|
  req.url '/api/direct_uploads'
  req.headers['Content-Type'] = 'application/json'
  req.body = { blob: { filename: filepath, byte_size: contents.bytesize, checksum: checksum, content_type: 'image/png' } }.to_json
  puts req.body
end

case JSON.parse(res.body, symbolize_names: true)
in { signed_id: signed_id, direct_upload: { url: s3_url, headers: s3_headers } }
end

raise if !signed_id

puts 'post S3'
uri = URI.parse(s3_url)
puts "#{uri.scheme}#{uri.host}#{uri.port} #{uri.path} #{uri.query}"
res = Faraday.new(url: "#{uri.scheme}://#{uri.host}:#{uri.port}").put do |req|
  req.url uri.path
  s3_headers.each do |k, v|
    req.headers[k.to_s] = v
  end
  URI.decode_www_form(uri.query).each do |(k, v)|
    req.params[k] = v
  end
  pp req
  req.body = contents
end
raise if !res.status != 200

puts 'PUT /api/users'
res = Faraday.new(url: 'http://localhost:3000').put do |req|
  req.url '/api/users'
  req.headers['Content-Type'] = 'application/json'
  req.headers['client'] = client
  req.headers['access-token'] = access_token
  req.headers['uid'] = uid
  req.body = { user: { training_id: user_id.to_i, porttait: signed_id } }.to_json
end
pp res.status
pp res.body
