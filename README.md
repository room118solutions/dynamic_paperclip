Dynamic Paperclip
=================

Dynamic Paperclip is an extension to the wonderful [Paperclip](http://github.com/thoughtbot/paperclip) gem
and Rack middleware that allows for the creation of Paperclip attachment styles on-the-fly.

Instead of defining your attachment styles in your model, Dynamic Paperclip allows you to generate URL's
for arbitrary attachment styles (usually in your view), effectively pushing style definition there.
When the browser requests that asset, if it has not already been processed, it is then processed on-the-fly
and sent back to the browser. If the style has already been processed, it's served just like any other static asset.

Getting started
---------------

### Requirements

Dynamic Paperclip requires Paperclip 3.5.0 or above and only currently supports Paperclip's File Storage.

### Application

Add the gem to your gemfile:

```ruby
gem 'dynamic_paperclip'
```

Run the ``bundle`` command to install it.

After you install the gem, you need to run the generator if you're using Rails:

```console
rails generate dynamic_paperclip:install
```

This will install an initializer that sets up a secret key used in validating that dynamic asset URL's
originated from your application.

If you are not using Rails, you need to set ``DynamicPaperclip.config.secret`` to some random string during
your application's boot process, check out [install_generator.rb](lib/generators/dynamic_paperclip/install_generator.rb) to see how the Rails generator does it.

You'll also need to configure your application to use the ``DynamicPaperclip::AttachmentStyleGenerator`` Rack middleware
if you are not using Rails.  This is configured automatically for Rails applications.

Now, you're ready to start using Dynamic Paperclip. Change any attachment definitions that you'd like to make dynamic from:

```ruby
has_attached_file :avatar
```

To:

```ruby
has_dynamic_attached_file :avatar
```

You can continue defining styles there, too, you don't need to move over entirely to dynamic styles. You can have both!

**Note:** Dynamic Paperclip requires that the ``:style`` **and** either the ``:id`` or ``:id_partition`` be included
in the ``:url`` that you specify when defining the attachment. Paperclip includes them by default, so this only
applies if you've specified your own.

Then, whenever you'd like a URL to a dynamic style, simply call ``#dynamic_url`` instead of ``#url`` on the attachment,
passing it the style definition that you would normally define in the ``:styles`` hash on ``has_attached_file``:

```ruby
@user.avatar.dynamic_url('100x100#')
```

### Server Configuration

If you're using your application to serve static assets, then no configuration is required.  But if you're not,
which you shouldn't be in any production environment, then you just need to make sure that your HTTP server
is configured to serve static assets if they exist, but pass the request along to your application
if they do not.

For example, on Nginx, this would be accomplished with something along the lines of:

```nginx
upstream rails {
  # ...
}

server {
  # ...

  try_files $uri @rails

  location @rails {
    # ...

    proxy_pass  http://rails;
  }
}
```

This basically says "If the requested URI exists, send that to the browser, if not, pass it along to the Rails app.",
and is a pretty standard Nginx setup.

Why?
----

Because as your application grows, you may discover that you have a large number of attachment styles.  This is
slowing down your requests, because every time a user attempts to upload a file, Paperclip must process each and every
one of those styles right then and there, in the middle of the request.

Also, when dealing with images, I think it makes more sense to specify the dimensions of a thumbnail in the view
that needs it, and not in the model.

How does this wizardry work?
---------------------------

It's pretty simple, actually.  Dynamic Paperclip includes a piece of Rack middleware that intercepts requests
for URLs to any dynamic attachments, generates the requested style if it doesn't exist, and sends it
back to the browser.

For example, in your model, you may define a dynamic attachment like this:

```ruby
class User
  has_dynamic_attached_file :avatar, url: '/system/:class/:attachment/:id/:style'
end
```

Then, in your view, you might call something like this:

```ruby
@user.avatar.dynamic_url('50x50')
```

Which will return the following url (assuming a JPG avatar and a User ID of 42):

```
/system/users/avatars/42/dynamic_50x50.jpg?s=secrethash
```

When your visitor's browser requests that URL, if that particular style has already been processed,
it'll be served up by your HTTP server (assuming it's configured correctly), but if it hasn't been processed yet,
Dynamic Paperclip's Rack middleware will intercept the request, validate that "secrethash" to ensure that the
dynamic URL was generated by your application and not some third-party, then simply tell Paperclip to process that
style by extracting the definition from the stye name, and then finally send it back to your visitor.

On subsequent requests, the attachment will already exist, and your HTTP server will simply return it without
ever hitting your Rails application.  Sweet!

If your HTTP server is not configured to serve static assets, the middleware will simply intercept the request
for the existing style and return it to the browser. It will not reprocess it. This is still far less efficient
than having your HTTP server serve the asset itself.

Contributing
------------

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

Known Issues
------------
- [ ] Dynamic attachments aren't registered in time when cache classing is disabled (Rails development, etc.).
      Since we register the attachment when it's defined, a request for a dynamic attachment in an environment
      where the class isn't preloaded will pass through the middleware, since the attachment won't be registered
      yet, and never generate.
