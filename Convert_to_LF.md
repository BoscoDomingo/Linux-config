# Convert files to LF

## Option 1 - Using git

[Source](https://stackoverflow.com/a/65628702/9022642)

Resets git, so we ensure changes are stashed.

```sh
git stash

git config core.autocrlf false

git rm --cached -r .         # Don’t forget the dot at the end

git reset --hard

git stash pop
```

## Option 2 - Using `find` and `dos2unix`

[Source 1](https://stackoverflow.com/a/61030524/9022642)
[Source 2](https://stackoverflow.com/questions/48692741/how-can-i-make-all-line-endings-eols-in-all-files-in-visual-studio-code-unix/61030524#61030524)

Change the `-name '...'` for `-type f` to get all files.
`-prune -false` is to avoid printing the excluded folders and is equivalent to `-prune [...] -print`, but we always need the `-print0` to pass to `dos2unix`.

```sh
find . -type d \( -name node_modules -o -name dist \) -prune -false -o -name '*.ts' -print0 | xargs -0 dos2unix
```

### Alternative 1

```sh
find . -type f \( -path "**/node_modules/*" -o -path "**/dist/*" \) -prune -false -o -name '*.ts' -print0 | xargs -0 dos2unix
```

### Alternative 2 (single excluded path)

```sh
find . -not -path "**/node_modules/*" -type f -print0 | xargs -0 dos2unix
```