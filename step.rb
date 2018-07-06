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
 
def reviewedComments? comments, last
  comment = comments.one? {|p| (p.updated_at > last) && p.body.downcase.include?('code review ok') }
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
   commits.map {|x| x.commit.author.date}.max
end
 
def reviewed? reviews, comments, last
  revs = reviewers reviews, last
  return reviewedComments?(comments, last) if revs.empty?
  revs.values.all?{|r| r}
end

def missing_reviewers reviews, last
  missing = []
  revs = reviewers reviews, last
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

branch = ENV["BITRISE_GIT_BRANCH"]
dest = ENV["BITRISEIO_GIT_BRANCH_DEST"]
matches = /:([^\/]*)\//.match ENV["GIT_REPOSITORY_URL"]

repo_base = matches[1]
repo = repo_base +  "/" + ENV["BITRISE_APP_TITLE"]
pull_id = ENV["PULL_REQUEST_ID"]
authorization_token = ENV["auth_token"]

log_fail "No authorization_token specified" if authorization_token.to_s.empty?
log_fail "No pull request specified" if pull_id.to_s.empty?

client = Octokit::Client.new access_token:authorization_token
pr = client.pull_request repo, pull_id
@author = pr.user.login 
comments = client.issue_comments repo , pull_id
comments.push(pr) if comments.empty?

commits = client.pull_request_commits repo, pull_id
lastCommit = last_commit(commits)
reviews = client.pull_request_reviews repo, pull_id
log_info "reviewed :#{ reviewed? reviews, comments, lastCommit}"
log_info "reviewers:#{reviewers(reviews, lastCommit)}"
options = {}
pr = client.pull_request repo, pull_id
inWIP(pr.title)

if reviewedComments? comments, lastCommit

  options[:merge_method] = "rebase" if pr.title.include? "bump version" 
end
  
if reviewed?(reviews, comments, lastCommit)
  #begin
  log_details "#{repo}, #{pull_id}  #{options}"
  resultMerge = client.merge_pull_request repo, pull_id ,'', options
  log_done "#{branch} merged #{options[:merge_method]}"
  export_output "BITRISE_AUTO_MERGE", "True"
  log_info "deleted :#{delete_branch? repo_base}"
  client.delete_branch repo, branch if delete_branch? repo_base
  log_info("#{dest} => #{resultMerge.merge}")
  if dest == "release" && resultMerge.merged?
    new_branch = "feat/reportRelease"
    client.create_ref repo, "heads/#{new_branch}", resultMerge.sha
    client.create_pull_request repo, "develop", new_branch, "chore(fix): report fixes", "code review OK"
  end
  # rescue Octokit::MethodNotAllowed
  #  client.merge repo, branch, dest, :merge_method => "rebase" 
  #end
else
  missings = missing_reviewers reviews, lastCommit
  exit(0) if missings.empty?
  missings.each {|m| client.add_comment repo, pull_id, "manque l'approbation de @#{m}"}
end

log_done "done"
