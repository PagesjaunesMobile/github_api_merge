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
 
def reviewedComments? comments
  comments.one? {|p| p.body.downcase.include? 'code review ok'}
end

def reviewers reviews
  revs ={}
  reviews.map{|r|
    revs[r.user.login] = r.state == "APPROVED"
  }
  
  revs.delete @author
  revs.delete "PJThor"
  revs
end
def reviewed? reviews, comments
  revs = reviewers reviews
  return reviewedComments?(comments) if revs.empty?
  revs.values.all?{|r| r}
end

def missing_reviewers reviews
  missing = []
  revs = reviewers reviews
  return missing if revs.empty?
  
  begin
    miss = revs.key(false)
    revs.delete(miss)
    missing.push miss
  end while revs.key(false)
  missing
end

def inWIP title
  if title.downcase.include? "wip"
    log_info "Abort : WIP mode detected"
    exit(0)
  end
end

log_info "init PR"

branch = ENV["BITRISE_GIT_BRANCH"]
dest = ENV["BITRISEIO_GIT_BRANCH_DEST"]


matches = /:([^\/]*)\//.match ENV["GIT_REPOSITORY_URL"]

repo_base = matches[1]
repo = repo_base +  "/" + ENV["BITRISE_APP_TITLE"]

authorization_token = ENV["auth_token"]

log_fail "No branch source specified" if branch.to_s.empty?

log_fail "No branch dest specified" if dest.to_s.empty?
log_fail "No authorization_token specified" if authorization_token.to_s.empty?


client = Octokit::Client.new access_token:authorization_token
pr = client.create_pull_request repo, branch, dest, "bump version", ""
log_fail "Pull request error" if pr.nil?
client.add_comment repo, pr.number, "code review OK"

log_done "done"
