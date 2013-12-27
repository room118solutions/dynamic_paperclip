## 1.0.0a (unreleased)
* Moved to Rack middleware strategy and thus removed Rails dependency entirely.
  Instead of exposing a Rails engine and adding routes to the host application
  to process dynamic attachment styles, we insert a piece of Rack middelware
  that serves the same purpose and is completely framework-agnostic.