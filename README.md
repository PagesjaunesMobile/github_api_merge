# Auto merge step

if tests are OK and a comment contains defined key
this step will automatically merge the Pull Request 

## How to use this Step
 * __Input__
   * _auth_token_: GitHub API Token. Required.
   * _reviewed_key_: Key to look for in comments. Case insensitive. Optional, default : "code review ok"
 * __Output__
   * _BITRISE_AUTO_MERGE_: Boolean, true if PR auto merged.
