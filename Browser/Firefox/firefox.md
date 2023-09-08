# Firefox

This serves to disable/remap shortcuts. Firefox still doesn't have a native way to do such a thing, but it's possible to do it with a little bit of JavaScript.

[Mozilla docs](https://support.mozilla.org/en-US/kb/customizing-firefox-using-autoconfig)
[List of available commands](https://searchfox.org/mozilla-release/source/browser/base/content/browser-sets.inc)
[Example](https://support.mozilla.org/en-US/questions/1342992#answer-1426736)
[Example Reddit post](https://www.reddit.com/r/firefox/comments/kilmm2/restore_ctrlshiftb_library_by_setting_configjs/)
[Example Reddit post #2](https://www.reddit.com/r/firefox/comments/kweasi/how_can_i_disable_specific_firefox_shortcuts/)

## Using it
Link the `autoload_custom_config.js` in `PATH_TO_FIREFOX/defaults/pref`
Link the `firefox_custom_config,js` in `PATH_TO_FIREFOX/` (where the firefox executable is)

### Windows

Linking from Ubuntu doesn't work on Windows, so you have to copy the files instead.

```ps
$LINUX_CONFIG_PATH="\\wsl.localhost\Ubuntu\home\bosco\repos\Linux-config"

cp "$LINUX_CONFIG_PATH\Firefox\defaults\pref\autoload_custom_config.js" "C:\Program Files\Mozilla Firefox\defaults\pref\"
cp "$LINUX_CONFIG_PATH\Firefox\firefox_custom_config.js" "C:\Program Files\Mozilla Firefox\"
```

### Linux

```sh
LINUX_CONFIG_PATH="/home/$USER/repos/Linux-config"
ln -s "$LINUX_CONFIG_PATH/Firefox/defaults/pref/autoload_custom_config.js" "/usr/lib/firefox/defaults/pref/autoload_custom_config.js"
ln -s "$LINUX_CONFIG_PATH/Firefox/firefox_custom_config.js" "/usr/lib/firefox/firefox_custom_config.js"
```