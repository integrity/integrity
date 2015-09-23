Make sure to re-hard link the upstart-envs file.  Docker won't use a symbolic link
so no "ln -s" here.
