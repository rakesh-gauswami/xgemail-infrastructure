name             'sophos-cloud-tomcat'
maintainer       'Mike Zraly'
maintainer_email 'mike.zraly@sophos.com'
license          'All rights reserved'
description      'Installs/Configures Tomcat'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.2.0'

depends 'sophos-cloud-smc'
depends 'sophos-cloud-fluentd'
depends 's3_file'
depends 'tar'
