require 'gitlab'

class Gitlab::Client
  module MergeRequests
    def rebase(project, id, options = {})
      log_done "rebase MR #{id}"
      put("/projects/#{url_encode project}/merge_requests/#{id}/rebase", body: {})
    end
  end
end


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
  return true if reviews.approved_by.size > 0
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


branch = ENV["BITRISE_GIT_BRANCH"]
dest = ENV["BITRISEIO_GIT_BRANCH_DEST"]
repo_base = ENV["GIT_REPOSITORY_URL"]
repo = repo_base[/:(.*).git/, 1]
pull_id = ENV["PULL_REQUEST_ID"]
authorization_token = ENV["AUTH_TOKEN"]
changelog = ENV["CHANGELOG"]

log_fail "No authorization_token specified" if authorization_token.to_s.empty?
log_fail "No pull request specified" if pull_id.to_s.empty?

client = Gitlab.client(
  endpoint: 'https://gitlab.solocal.com/api/v4',
  private_token: authorization_token )
pr = client.merge_request repo, pull_id

@author = pr.author.username 
comments = client.merge_request_notes repo , pull_id

commits = client.merge_request_commits repo, pull_id
lastCommit = last_commit(commits)
reviews = client.merge_request_approvals repo, pull_id
log_info "reviewed :#{ reviewed? reviews, comments, lastCommit}"
options = {}
pr = client.merge_request repo, pull_id
inWIP(pr, changelog)

if reviewedComments? comments, lastCommit

  options[:merge_method] = "rebase" if pr.title.include? "bump version" 
end
  
if reviewed?(reviews, comments, lastCommit)
  #begin
  log_details "#{repo}, #{pull_id}  #{options}"
  resultMerge = client.accept_merge_request repo, pull_id, { merge_when_pipeline_succeeds: true }
  log_done "#{branch} merged #{options[:merge_method]}"
  export_output "BITRISE_AUTO_MERGE", "True"
  log_info "deleted :#{delete_branch? repo_base}"
#  client.delete_branch repo, branch 
  if dest == "release" && resultMerge.state == "merged"
    new_branch = "feat/reportRelease"
    client.create_ref repo, "heads/#{new_branch}", resultMerge.sha
    client.create_merge_request repo, "chore(fix): report fixes", { source_branch: new_branch, target_branch: 'develop', description: "code review OK", approvals_before_merge: 0}

  end
  
  nextMR = client.merge_requests(repo, {state: "opened", approved_by_ids: "Any"}) 
  begin
    client.rebase repo, nextMR.select { |item| item.iid != pull_id }.first.iid
  rescue => ex
    log_done "Nothing left to do ...#{ex}"
  end
  
  # rescue Octokit::MethodNotAllowed
  #  client.merge repo, branch, dest, :merge_method => "rebase" 
  #end
  #else
#  miss = client.merge_request_review_requests repo, pull_id 
#  missings = miss.users.map {|p| p.login}
#  missings = missing_reviewers missings, reviews, lastCommit
#  exit(0) if missings.empty?
#  missings.each {|m| client.add_comment repo, pull_id, "manque l'approbation de @#{m}"}
end

log_done "done"
