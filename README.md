repo="thehunterofshadows/project_files"
branch="main"
curl -fsSL "https://codeload.github.com/$repo/tar.gz/refs/heads/$branch" \
  | tar -xz --wildcards --strip-components=1 '*/*.sh'
chmod +x ./*.sh 2>/dev/null || true
