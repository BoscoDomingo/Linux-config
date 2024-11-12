To update ZSH, you'll need to temporarily rename the symlink directly in oh-my-zsh's home directory

```zsh
cd "$ZSH"
mv custom old-custom
omz update
mv old-custom custom
```