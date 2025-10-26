base="https://raw.githubusercontent.com/thehunterofshadows/project_files/main"
for f in checkpoint.sh restore.sh clean.sh filewatch.sh tmux_start.sh; do
  curl -fsSL -o "$f" "$base/$f"
done
chmod +x checkpoint.sh restore.sh clean.sh
echo "✅ Updated checkpoint.sh, restore.sh, clean.sh"
