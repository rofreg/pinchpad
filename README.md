# Pinch Pad

Pinch Pad is a simple app for creating quick sketches and animations. You can post your drawings to Twitter and Tumblr in a single tap, or share your creations through any other method that iOS supports (save to Camera Roll, send via email, Airdrop, etc.)

## Why?

Pinch Pad was built to help me do [hourly comics](https://www.pinchpad.com)! If you're someone who draws a lot, and you want to ability to share your drawings with one touch (rather than manually composing a new Tweet every time), then Pinch Pad is a great little sketch app for you.

## Setup

Basic setup instructions:

- Run `pod install`
- Configure Twitter
  - Set up a Twitter app account, then add your Twitter consumer key and secret:
    - `bundle exec pod keys set TwitterConsumerKey VALUE`
    - `bundle exec pod keys set TwitterConsumerSecret VALUE`
- Configure Tumblr
  - Set up a Tumblr app account, then add your Tumblr consumer key and secret:
    - `bundle exec pod keys set TumblrConsumerKey VALUE`
    - `bundle exec pod keys set TumblrConsumerSecret VALUE`
- Configure Mastodon (optional)
  - Set up a Mastodon developer app, then add your Mastodon access key and secret:
    - `bundle exec pod keys set MastodonBaseUrl VALUE`
    - `bundle exec pod keys set MastodonAccessToken VALUE`
  - If you don't want to use Mastodon, run the above commands with VALUE set to an empty string

## Who made this?

[@rofreg](https://github.com/rofreg) did. You can check out some of the other things I've built on my [website](https://rofreg.com)!
