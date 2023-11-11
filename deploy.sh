commit_message=${1:-"update"}
git add -A
git commit -m "$commit_message"
git push
hexo clean
hexo generate
hexo deploy