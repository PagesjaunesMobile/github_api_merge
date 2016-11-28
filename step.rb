require 'octokit'


# --------------------------
# --- Constants & Variables
# --------------------------

@this_script_path = File.expand_path(File.dirname(__FILE__))

# --------------------------
# --- Functions
# --------------------------

def log_fail(message)
  puts
  puts "\e[31m#{message}\e[0m"
  exit(1)
end

def log_warn(message)
  puts "\e[33m#{message}\e[0m"
end

def log_info(message)
  puts
  puts "\e[34m#{message}\e[0m"
end

def log_details(message)
  puts "  #{message}"
end

def log_done(message)
  puts "  \e[32m#{message}\e[0m"
end

def export_output(out_key, out_value)
 IO.popen("envman add --key #{out_key.to_s}", 'r+') { |f|
    f.write(out_value.to_s)
    f.close_write
    f.read
  }
end

def delete_branch? host
  ENV["BITRISEIO_PULL_REQUEST_REPOSITORY_URL"].include? host
end
 
def reviewed? comments
  comments.one? {|p| p.body.downcase.include? 'code review ok'}
end

log_info "init Merge"
branch = ENV["BITRISE_GIT_BRANCH"]
matches = /:([^\/]*)\//.match ENV["GIT_REPOSITORY_URL"]
repo_base = matches[1]
repo = repo_base +  "/" + ENV["BITRISE_APP_TITLE"]
pull_id = ENV["BITRISE_PULL_REQUEST"]
authorization_token = ENV["auth_token"]

  log_fail "No authorization_token specified" if authorization_token.to_s.empty?

  log_fail "No pull request specified" if pull_id.to_s.empty?

client = Octokit::Client.new access_token:authorization_token

comments = client.issue_comments repo , pull_id

log_info "reviewed :#{ reviewed? comments}"
if reviewed? comments
  client.merge_pull_request repo, pull_id 
  log_done "#{branch} merged"
  export_output "BITRISE_AUTO_MERGE", "True"
  log_info "deleted :#{delete_branch? repo_base}"
  client.delete_ref branch if delete_branch? repo_base
end

  log_done "done"