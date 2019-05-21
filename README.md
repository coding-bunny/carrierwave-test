# README
This is a simple project for CarrierWave to understand and research the difference between 1.0.0 and 1.3.0
In 1.0.0 the S3ShardedStorage works properly and deleted files are working.
In 1.3.0 this behavior changes and deleted files are failing tests

# RSpec
simply run `bundle exec rspec` to fire up the tests

# CarrierWave version
toggle the lines in the Gemfile and run the tests

* 1.0.0 : all pass
* 1.3.0 : delete specs fail
