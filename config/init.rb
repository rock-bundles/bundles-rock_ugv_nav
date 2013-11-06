Roby.app.using 'syskit'

require 'roby/schedulers/temporal'
Roby.scheduler = Roby::Schedulers::Temporal.new

## Uncomment to enable automatic transformer configuration support
Syskit.conf.transformer_enabled = true

