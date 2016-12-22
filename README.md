# vfs-rsync-upload

For background see [this](https://criztovyl.space/2016/10/15/rsync-remote-sftp-publishing/) post :)

##Setup a project

To set up the remotes for project (any directory) run the command below.

`/path/to/mount` is the mount point of the remote directory, `dist` the directory you want to upload (e.g. also `.`) and `myproject` is the configuration name.

```bash
vfs-rsync-upload setup /path/to/mount dist myproject "--exclude /piwik --exclude /blog"
```

This creates some files and directories:

* a `.p12g` file in the current directory, containing a configuration key, which is appended to your configuration name to prevent name collisions.
* a `.p12g` directory in your home ("p12g" for "publishing") and
* a `myproject-configKey` directory in `$HOME/.p12g`, with the structure outlined below:

        remotes
            production (symlink to /path/to/mount)
            qa (symlink to /path/to/mount/qa)
            staging (symlink to /path/to/mount/staging)
        mirror
            production (dir)
            qa (dir)
            staging (dir)
        batch
            production (dir)
            qa (dir)
            staging (dir)
        sync_dir (symlink to dist)

Afterwards it synchronizes the folders in `remote` with the folders in `mirror`, using `rsync`, appending the contents of the fifth argument to the defaults arguments (`--write-batch=batch`), but note that this will not synchronize the contents of the current directory instantly. Maybe I’ll add an option for that later.

#Upload files

```bash
$ vfs-rsync-upload staging
```

This uploads the contents of `dist`, as you set up above. As first this will `rsync` the local mirror (`mirror/staging`) and the directory (`dist`) and write a batch (`batch/staging/batch` and `batch/staging/batch.sh`). Afterwards it calls the `batch.sh` and uploads the changes to your remote directory. Currently only `staging`, `qa` and `production` are supported. In future you should be able to define your own targets, too.
