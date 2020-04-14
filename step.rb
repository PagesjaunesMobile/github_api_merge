require 'gitlab'


class Comments_light
  attr_reader :body, :updated_at
  
  def initialize(body: '', updated_at: '')
    @body = body
    @updated_at = updated_at
  end
end  

# --------------------------
# --- Constants & Variables
# --------------------------

@this_script_path = File.expand_path(File.dirname(__FILE__))
DISMISS_APPROVALS_FEATURE = false
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
 
def reviewedComments? comments, last
  comment = comments.any? {|p| (p.updated_at > last) && p.body.downcase.include?('code review ok') }
end

def reviewers reviews, last
  revs ={}
  reviews.map{|r|
    revs[r.user.login] = r.state == "APPROVED" && r.submitted_at > last
  }
  
  revs.delete @author
  revs.delete "PJThor"
  revs
end

def last_commit commits
  return commits.map {|x| x.committed_date}.min unless DISMISS_APPROVALS_FEATURE
   commits.map {|x| x.committed_date}.max
end
 
def reviewed? reviews, comments, last
  return true if reviews.approved == true
  return reviewedComments?(comments, last)
end

def missing_reviewers missing, reviews, last
  revs = reviewers reviews, last
  return missing if revs.empty?
  
  begin
    miss = revs.key(false)
    revs.delete(miss)
    missing.push miss
  end while revs.key(false)
  missing
end

def inWIP pr, changelog
  labels = pr.labels.map {|l| l.name}.reject(&:blank?)
  labels.push pr.title
  if labels.any? { |l| l.downcase.include? "wip"}
    log_warn "Abort : WIP mode detected"
    exit(0)
  end
end

log_info "init PR"

branch = ENV["BITRISE_GIT_BRANCH"]
dest = ENV["BITRISEIO_GIT_BRANCH_DEST"]
repo_base = ENV["GIT_REPOSITORY_URL"]
repo = repo_base[/:(.*).git/, 1]
authorization_token = ENV["AUTH_TOKEN"]
changelog = ENV["CHANGELOG"]

log_fail "No branch source specified" if branch.to_s.empty?
log_fail "No branch dest specified" if dest.to_s.empty?
log_fail "No authorization_token specified" if authorization_token.to_s.empty?

client = Gitlab.client(
  endpoint: 'https://gitlab.solocal.com/api/v4',
  private_token: authorization_token )
end

pr = client.create_merge_request repo, "bump version", {source_branch: branch, target_branch: dest}
log_fail "Pull request error" if pr.nil?
client.create_merge_request_note repo, pr.iid, "code review OK"

log_done "done"
