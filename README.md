# ErrbitGitlabPlugin

This gem adds Gitlab issue tracker support to Errbit.

Version 1.0 is compatible with Errbit 0.4.

For (much) older versions of Errbit, try the 0.x gem versions or consider
updating your Errbit installation

## Installation

As described in [Errbit's README](https://github.com/errbit/errbit#plugins-and-integrations), 
just add the gem to your `UserGemfile`:

    echo "gem 'errbit_gitlab_plugin'" > UserGemfile

And then execute:

    $ bundle

## Usage

Simply add your Gitlab URL, private token and project name to your errbit app.

You can find your private token by clicking on "Account" in your Gitlab profile settings.

Upon saving the app, the gem will automatically test if your entered
credentials are valid and inform you otherwise.

## Troubleshoot

> I entered my Gitlab settings and the tracker was saved, but I cannot create issues

The Gitlab API (at least on gitlab.com) does not seem to accept POST requests when using
a non-encrypted connection. Therefore, please make sure to use `https://` when
using gitlab.com as URL.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
