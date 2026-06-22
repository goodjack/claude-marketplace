# GitHub PR Review Threads API 模板

背景：gh CLI 沒有 review thread 的原生指令（cli/cli#12419），resolve 只能走 GraphQL；
`isResolved` 狀態 REST API 也查不到。回覆可走 GraphQL（用 threadId）或 REST（用留言
databaseId），兩者擇一即可，本文件以 GraphQL 為主、REST 為備援。

執行時把 `{owner}` `{repo}` `{pr}` `{threadId}` 替換成實際值。

## 撈出全部 review threads（含解決狀態）

```bash
gh api graphql -f query='
query($owner: String!, $repo: String!, $pr: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $pr) {
      author { login }
      reviewThreads(first: 50) {
        pageInfo { hasNextPage endCursor }
        nodes {
          id
          isResolved
          isOutdated
          path
          line
          comments(first: 20) {
            nodes {
              databaseId
              author { login }
              body
              createdAt
            }
          }
        }
      }
    }
  }
}' -F owner='{owner}' -F repo='{repo}' -F pr={pr}
```

- 只看未解決：jq `.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved | not)`
- threads 超過 50 個時用 `pageInfo.endCursor` 翻頁（`reviewThreads(first: 50, after: $cursor)`）
- `isOutdated == true` 表示留言對應的程式碼行已被後續 commit 改掉，查證時要看最新程式碼而非留言當下的 diff

## 回覆某個 thread

GraphQL（建議，直接用上一步拿到的 threadId）：

```bash
gh api graphql -f query='
mutation($threadId: ID!, $body: String!) {
  addPullRequestReviewThreadReply(input: {pullRequestReviewThreadId: $threadId, body: $body}) {
    comment { url }
  }
}' -F threadId='{threadId}' -f body='回覆內容，支援 Markdown'
```

REST 備援（`{comment_id}` 必須是 thread 第一則留言的 databaseId，對回覆留言的 id 會 404）：

```bash
gh api repos/{owner}/{repo}/pulls/{pr}/comments/{comment_id}/replies -f body='回覆內容'
```

注意：body 內含反引號、雙引號時用單引號包整段並以 `-f` 傳入，避免 shell 展開。

## 編輯 / 刪除自己的回覆

編輯（更正方式先依 SKILL.md 詢問使用者；body 是整段取代，記得保留署名）：

```bash
gh api -X PATCH repos/{owner}/{repo}/pulls/comments/{comment_id} -f body='完整新內容'
```

刪除（破壞性操作，先取得使用者同意）：

```bash
gh api -X DELETE repos/{owner}/{repo}/pulls/comments/{comment_id}
```

`{comment_id}` 用留言的 databaseId。編輯不會發通知，會留下 edited 標記與編輯歷史。

## Resolve / Unresolve conversation

```bash
gh api graphql -f query='
mutation($threadId: ID!) {
  resolveReviewThread(input: {threadId: $threadId}) {
    thread { id isResolved }
  }
}' -F threadId='{threadId}'
```

誤按可還原：把 `resolveReviewThread` 換成 `unresolveReviewThread` 即可。

權限：需要 repo Contents 的 Read and Write（一般 collaborator 即有）。

## PR 基本資訊與 diff（查證用）

```bash
gh pr view {pr} --repo {owner}/{repo} --json title,author,baseRefName,headRefName,state,body,files
gh pr diff {pr} --repo {owner}/{repo}
```

若本地分支就是 PR 的 head branch，直接在本地 grep/Read 查證最快，也能直接修正。
