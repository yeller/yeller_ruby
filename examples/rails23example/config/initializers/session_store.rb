# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_rails23example_session',
  :secret      => 'a99e0c9b6b88deac55e31e9abee8ea8d155d35426b66f6c5cde62c2412412a6aadcf2432e97ccc05d1695e5ff8161fe855f3cec6749f060b6bfde68140682f79'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
